module Pages.Components.ShoppingListDeleteForm where

import Prelude

import Data.Number (fromString)
import Data.List (List (..), (:), sortBy, filter)
import Data.Array (fromFoldable)
import Data.Either (Either (..), either)
import Data.Maybe (Maybe (..))
import Data.Set (Set(..), empty, member, insert, delete)

import Control.Alt((<|>))
import Control.Comonad (extract)

import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Exception (Error)
import Control.Monad.Aff (Aff, attempt, delay)
import Control.Monad.Aff.Console (log, CONSOLE)
import Control.Parallel (parallel, sequential)
import Data.Foldable (for_)

import Control.Monad.Eff.Now (NOW, nowDateTime)
import Data.Time.Duration (Milliseconds (..))
import Data.Formatter.DateTime (FormatterCommand (YearFull, Placeholder, MonthTwoDigits, DayOfMonthTwoDigits), format)

import Data.Argonaut (Json, class DecodeJson, decodeJson, (.?), (:=), (~>), jsonEmptyObject)
import Data.Argonaut.Parser (jsonParser)
import Data.HTTP.Method (Method(..))
import Network.HTTP.Affjax (AJAX, get, affjax, defaultRequest) as AJ
import Network.HTTP.StatusCode (StatusCode(..))

import Pux (EffModel, noEffects, onlyEffects)
import Pux.DOM.HTML (HTML)
import Pux.DOM.Events (DOMEvent, onClick, onSubmit, targetValue)

import DOM (DOM)
import DOM.Event.Event (preventDefault)

import Text.Smolder.HTML (h1, h2, img, ul, li, label, table, th, tr, td, strong)
import Text.Smolder.HTML.Attributes (src, value, style, checked, disabled)
import Text.Smolder.Markup ((!), (#!), text)

import Utilities
import Pages.Components
import App.Component as AppComp



data ExternalEvent =
    AddEntry Entry
  | Reload


newtype Entry = Entry
  { id :: Int
  , category :: String
  , name :: String }

instance decodeJsonEntry :: DecodeJson Entry where
  decodeJson json = do
    obj <- decodeJson json
    id <- obj .? "id"
    category <- obj .? "category"
    name <- obj .? "name"
    pure $ Entry { id: id, category: category, name: name }


instance appComponentEvent :: AppComp.ComponentEvent Event where
  getAppEvent (Ajax GetEntriesError) = AppComp.UserMessage "Fehler beim Laden von Daten"
  getAppEvent (Ajax DeleteEntriesError) = AppComp.UserMessage "Fehler beim Senden von Daten"
  getAppEvent _ = AppComp.NoOp



data Event =
    Init
  | Ajax AjaxEvent
  | Form FormEvent
  | External ExternalEvent

data AjaxEvent =
    GetEntries
  | GetEntriesSuccess (List Entry)
  | GetEntriesError
  | DeleteEntries
  | DeleteEntriesSuccess
  | DeleteEntriesError

data FormEvent =
    ToggleId Int DOMEvent
  | Submit DOMEvent



type State =
  { ajaxState :: AjaxState
  , entries :: List Entry
  , checkedIds :: Set Int    -- set with ids of checked entries
  }

data AjaxState =
    Idle
  | GettingEntries
  | DeletingEntries



init :: State
init =
  { ajaxState : GettingEntries
  , entries : Nil
  , checkedIds : empty
  }



view :: State -> HTML Event
view { ajaxState, entries, checkedIds } = do
  h1 $ text "Einkaufsliste"
  customForm buttonText isActive #! onSubmit (Form <<< Submit) $
    table ! style "text-align: left;" $ do
      tr $ do
        th ! style "width: 1%;" $ text "Kategorie"
        th $ text "Artikel"
        th ! style "width: 1%;" $ pure unit
      for_ entries entryRow
  where
    entryRow (Entry entry) =
      tr #! onClick (Form <<< ToggleId entry.id) $ do
        td $ strong $ text entry.category
        td $ text entry.name
        td $ if entry.id `member` checkedIds
          then checkbox ! checked "true"
          else checkbox ! checked ""
    buttonText = case ajaxState of
      Idle -> "Löschen"
      GettingEntries -> "Lade..."
      DeletingEntries -> "Lösche Einträge..."
    isActive = case ajaxState of
      Idle -> true
      _ -> false



foldp :: forall eff. Event -> State
  -> EffModel State Event (ajax :: AJ.AJAX, console :: CONSOLE, dom :: DOM, now :: NOW | eff)
foldp Init state =
  { state : state
  , effects : [ pure $ Just $ Ajax GetEntries ] }

foldp (Ajax GetEntries) state =
  { state: state { ajaxState = GettingEntries }
  , effects: [ getEntries ] }
foldp (Ajax (GetEntriesSuccess entries)) state =
  noEffects $ state
    { ajaxState = Idle
    , entries = entries }
foldp (Ajax GetEntriesError) state =
  onlyEffects state [ pure $ Just $ Ajax GetEntries ]

foldp (Ajax DeleteEntries) state@{checkedIds} =
  { state: state { ajaxState = DeletingEntries }
  , effects: [ deleteEntries checkedIds ] }
foldp (Ajax DeleteEntriesSuccess) state@{checkedIds, entries} =
  noEffects $ state
    { ajaxState = Idle
    , checkedIds = (empty :: Set Int)
    , entries = filter (\(Entry x) -> not $ x.id `member` checkedIds) entries }
foldp (Ajax DeleteEntriesError) state =
  { state: state { checkedIds = (empty :: Set Int) }
  , effects: [ pure $ Just $ Ajax GetEntries ] }

foldp (Form (ToggleId id ev)) state@{checkedIds} =
  noEffects $ state {checkedIds = toggledIds}
  where
    toggledIds = if id `member` checkedIds
      then delete id checkedIds
      else insert id checkedIds
foldp (Form (Submit ev)) state =
  onlyEffects state [ do
    liftEff (preventDefault ev)
    pure $ Just $ Ajax DeleteEntries
    ]

foldp (External (AddEntry entry)) state@{entries} =
  noEffects state
    { entries = entry `Cons` entries
    }
foldp (External Reload) state =
  onlyEffects state [pure $ Just $ Ajax GetEntries]


-- | Get entries. If there is a recoverable error, wait a second and retry.
-- | If no answer from server after ten seconds, retry.
getEntries :: forall eff. Aff (ajax :: AJ.AJAX, console :: CONSOLE | eff) (Maybe Event)
getEntries = do
  maybeRes <- attemptWithTimeout 10000.0 (getWithoutCaching "/backend/api/shoppinglist/entries.php")
  case maybeRes of
    Just (Right res) | res.status == (StatusCode 200) -> do
      let entries = decodeEntries =<< jsonParser res.response
      either
        (log >=> const (pure $ Just $ Ajax GetEntriesError))
        (pure <<< Just <<< Ajax <<< GetEntriesSuccess)
        entries
    -- | If status is not 200, we expect an object of the form {error: String}
    Just (Right res) -> do
      log $ "Error: Expected status 200, received " <> (\(StatusCode n) -> show n) res.status <> " while fetching entries."
      log $ "Response from server:"
      log res.response
      pure $ Just $ Ajax GetEntriesError
    Just (Left err) -> do
      log $ show err
      delay $ Milliseconds 1000.0
      pure $ Just $ Ajax GetEntriesError
    Nothing -> do
      log $ "Error: Request timed out while getting entries."
      pure $ Just $ Ajax GetEntriesError


deleteEntries :: forall eff. Set Int -> Aff (ajax :: AJ.AJAX, console :: CONSOLE | eff) (Maybe Event)
deleteEntries checkedIds = do
  maybeRes <- attemptWithTimeout 10000.0 $ AJ.affjax deleteRequest
  case maybeRes of
    Just (Right res) | res.status == (StatusCode 200) -> do
      pure $ Just $ Ajax DeleteEntriesSuccess
    -- If status is not 200, we expect an object of the form {error: String}
    Just (Right res) -> do
      log $ "Error: Expected status 200, received " <> (\(StatusCode n) -> show n) res.status <> " while deleting entries."
      log $ "Response from server:"
      log res.response
      pure $ Just $ Ajax DeleteEntriesError
    Just (Left err) -> do
      log $ show err
      pure $ Just $ Ajax DeleteEntriesError
    Nothing -> do
      log $ "Error: Request timed out while deleting entries."
      pure $ Just $ Ajax DeleteEntriesError
  where
    deleteRequest = AJ.defaultRequest
      { method = Left DELETE
      , url = "/backend/api/shoppinglist/entries.php"
      , content = Just $ encodeCheckedIds checkedIds
      }



decodeEntries :: Json -> Either String (List Entry)
decodeEntries r = do
  obj <- decodeJson r
  entries <- obj .? "entries"
  decodeJson entries

encodeCheckedIds :: Set Int -> Json
encodeCheckedIds ids =
  "ids" := fromFoldable ids
  ~> jsonEmptyObject
