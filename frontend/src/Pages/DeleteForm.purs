module Pages.DeleteForm where

import Prelude

import Data.Number (fromString)
import Data.List (List (..), (:), sortBy)
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
import Network.HTTP.Affjax (AJAX, get, post)
import Network.HTTP.StatusCode (StatusCode(..))

import Pux (EffModel, noEffects, onlyEffects)
import Pux.DOM.HTML (HTML)
import Pux.DOM.Events (DOMEvent, onClick, onSubmit, targetValue)

import DOM (DOM)
import DOM.Event.Event (preventDefault)

import Text.Smolder.HTML (h1, h2, img, ul, li, label, table, th, tr, td, strong)
import Text.Smolder.HTML.Attributes (src, value, style, checked, disabled)
import Text.Smolder.Markup ((!), (#!), text)

import Pages.Utilities
import Pages.Components
import App.Component as AppComp



data Event =
    Init
  | Ajax AjaxEvent
  | Form FormEvent

data AjaxEvent =
    GetEntries
  | GetEntriesSuccess (List Entry)
  | GetEntriesError
--  | DeleteEntries (List Int)
--  | DeleteEntriesSuccess
--  | DeleteEntriesError

data FormEvent =
    ToggleId Int DOMEvent
--  | Submit DOMEvent

instance appComponentEvent :: AppComp.ComponentEvent Event where
  getAppEvent (Ajax GetEntriesError) = AppComp.UserMessage "Fehler beim Laden von Daten"
--  getAppEvent (Ajax DeleteEntriesError) = AppComp.UserMessage "Fehler beim Senden von Daten"
  getAppEvent _ = AppComp.NoOp



type State =
  { ajaxState :: AjaxState
  , entries :: List Entry
  , checkedIds :: Set Int    -- array with ids of checked entries
  }

data AjaxState =
    NoOp
  | GettingEntries
--  | DeletingEntries
  | Error


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


init :: State
init =
  { ajaxState : GettingEntries
  , entries : Nil
  , checkedIds : empty
  }



view :: State -> HTML Event
view { ajaxState, entries, checkedIds } = do
  h2 $ text "Einkaufsliste"
  customForm "Löschen" false $ table ! style "text-align: left;" $ do
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
-- TODO: Delete-Button-Logik



foldp :: forall eff. Event -> State
  -> EffModel State Event (ajax :: AJAX, console :: CONSOLE, dom :: DOM, now :: NOW | eff)
foldp Init state =
  { state : state
  , effects : [ pure $ Just $ Ajax GetEntries ]
  }

foldp (Ajax GetEntries) state =
  { state: state { ajaxState = GettingEntries }
  , effects: [ getEntries ]
  }
foldp (Ajax (GetEntriesSuccess entries)) state =
  noEffects $ state
    { ajaxState = NoOp
    , entries = entries
    }
foldp (Ajax GetEntriesError) state =
  noEffects $ state { ajaxState = Error }

foldp (Form (ToggleId id ev)) state@{checkedIds} =
  noEffects $ state {checkedIds = toggledIds}
  where
    toggledIds = if id `member` checkedIds
      then delete id checkedIds
      else insert id checkedIds


-- | Get entries. If there is a recoverable error, wait a second and retry.
-- | If no answer from server after ten seconds, retry.
-- | Otherwise success or fatal error.
getEntries :: forall eff. Aff (ajax :: AJAX, console :: CONSOLE | eff) (Maybe Event)
getEntries = do
  maybeRes <- attemptWithTimeout (get "/backend/api/shoppinglist/entries.php") 10000.0
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
      pure $ Just (Ajax GetEntriesError)
    Just (Left err) -> do
      log $ show err
      delay $ Milliseconds 1000.0
      pure $ Just $ Ajax GetEntries
    Nothing -> do
      log $ "Error: Request timed out while getting entries."
      pure $ Just $ Ajax GetEntries


decodeEntries :: Json -> Either String (List Entry)
decodeEntries r = do
  obj <- decodeJson r
  entries <- obj .? "entries"
  decodeJson entries
