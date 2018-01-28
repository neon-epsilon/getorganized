module Pages.InputForm where

import Prelude

import Data.Number (fromString)
import Data.List (List (..), (:), sortBy)
import Data.Either (Either (..), either)
import Data.Maybe (Maybe (..))

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
import Pux.DOM.Events (DOMEvent, onChange, onSubmit, targetValue)

import DOM (DOM)
import DOM.Event.Event (preventDefault)

import Text.Smolder.HTML (h1, h2, img, ul, li, label, table, th, tr, td, strong)
import Text.Smolder.HTML.Attributes (src, value, style)
import Text.Smolder.Markup ((!), (#!), text)

import Pages.Utilities
import Pages.Components
import App.Component as AppComp



data Event =
    Init
  | Ajax AjaxEvent
  | Form FormEvent

data AjaxEvent =
    GetCategories
  | GetCategoriesSuccess (List Category)
  | GetCategoriesError
  | PostEntry
  | PostEntrySuccess
  | PostEntryError

data FormEvent = Submit DOMEvent
  | NameChange DOMEvent
  | CategoryChange DOMEvent

instance appComponentEvent :: AppComp.ComponentEvent Event where
  getAppEvent (Ajax GetCategoriesError) = AppComp.UserMessage "Fehler beim Laden von Daten"
  getAppEvent (Ajax PostEntryError) = AppComp.UserMessage "Fehler beim Senden von Daten"
  getAppEvent _ = AppComp.NoOp



type State =
  { ajaxState :: AjaxState
  , categories :: List Category
  , formState :: FormState }

data AjaxState =
    NoOp
  | GettingCategories
  | PostingEntry
  | Error


newtype Category = Category
  { category :: String
  , priority :: Int }

instance decodeJsonCategory :: DecodeJson Category where
  decodeJson json = do
    obj <- decodeJson json
    category <- obj .? "category"
    priority <- obj .? "priority"
    pure $ Category { category: category, priority: priority }


type FormState =
  { name :: String
  , category :: String }


init :: State
init =
  { ajaxState : GettingCategories
  , categories : Nil
  , formState : initFormState }

initFormState :: FormState
initFormState =
  { name : ""
  , category: "" }



view :: State -> HTML Event
view { ajaxState, categories, formState } = do
  h1 $ text "Einkaufsliste"
  h2 $ text "Artikel eingeben"
  customForm buttonText isActive #! onSubmit (Form <<< Submit) $ ul $ do
    li $ do
      label $ text "Artikel:"
      textInput ! value formState.name #! onChange (Form <<< NameChange)
    li $ do
      label $ text "Kategorie:"
      customSelect
        (map
        ( \(Category x) -> {value : x.category, text : x.category} )
        categories)
        ! value formState.category
        #! onChange (Form <<< CategoryChange)
  where
    buttonText = case ajaxState of
      NoOp -> "Speichern"
      GettingCategories -> "Lade..."
      PostingEntry -> "Sende Daten..."
      Error -> "Fehler"
    isActive = case ajaxState of
      NoOp -> true
      _ -> false



foldp :: forall eff. Event -> State
  -> EffModel State Event (ajax :: AJAX, console :: CONSOLE, dom :: DOM, now :: NOW | eff)
foldp Init state =
  { state : state
  , effects : [ pure $ Just $ Ajax GetCategories ]
  }

foldp (Ajax GetCategories) state =
  { state: state { ajaxState = GettingCategories }
  , effects: [ getCategories ]
  }
-- | Receive categories and store them sorted by their priority value
-- | If the received list is empty, set ajaxState = Error as we
-- | cannot recover from this state without action on the server side.
foldp (Ajax (GetCategoriesSuccess categories)) state@{ formState } =
  case categories of
    ((Category x) : xs) -> noEffects $ state
      { ajaxState = NoOp
      , categories = sortBy (comparing (\(Category c) -> c.priority)) categories
      , formState = formState { category = x.category }
      }
    Nil -> onlyEffects state [ do
      log "Error: Received empty list of categories from server."
      pure $ Just $ Ajax GetCategoriesError
      ]
foldp (Ajax GetCategoriesError) state =
  noEffects $ state { ajaxState = Error }
foldp (Ajax PostEntry) state =
  { state: state { ajaxState = PostingEntry }
  , effects: [ postEntry state.formState ]
  }
foldp (Ajax PostEntrySuccess) state@{ formState, ajaxState } =
  noEffects $ state
    { formState = formState { name = "" }
    , ajaxState = NoOp }
foldp (Ajax PostEntryError) state =
  noEffects $ state
    { ajaxState = NoOp }

foldp (Form (Submit ev)) state =
  onlyEffects state [ do
    liftEff (preventDefault ev)
    pure $ Just $ Ajax PostEntry
    ]
foldp (Form (NameChange ev)) state@{ formState } =
  noEffects $ state { formState = formState { name = targetValue ev } }
foldp (Form (CategoryChange ev)) state@{ formState } =
  noEffects $ state { formState = formState { category = targetValue ev } }


-- | Get categories. If there is a recoverable error, wait a second and retry.
-- | If no answer from server after ten seconds, retry.
-- | Otherwise success or fatal error.
getCategories :: forall eff. Aff (ajax :: AJAX, console :: CONSOLE | eff) (Maybe Event)
getCategories = do
  maybeRes <- attemptWithTimeout (get "/backend/api/shoppinglist/categories.php") 10000.0
  case maybeRes of
    Just (Right res) | res.status == (StatusCode 200) -> do
      let categories = decodeCategories =<< jsonParser res.response
      either
        (log >=> const (pure $ Just $ Ajax GetCategoriesError))
        (pure <<< Just <<< Ajax <<< GetCategoriesSuccess)
        categories
    -- | If status is not 200, we expect an object of the form {error: String}
    Just (Right res) -> do
      log $ "Error: Expected status 200, received " <> (\(StatusCode n) -> show n) res.status <> " while fetching categories."
      log $ "Response from server:"
      log res.response
      pure $ Just (Ajax GetCategoriesError)
    Just (Left err) -> do
      log $ show err
      delay $ Milliseconds 1000.0
      pure $ Just $ Ajax GetCategories
    Nothing -> do
      log $ "Error: Request timed out while getting categories."
      pure $ Just $ Ajax GetCategories


postEntry :: forall eff. FormState -> Aff (ajax :: AJAX, console :: CONSOLE | eff) (Maybe Event)
postEntry formState = do
  r <- attempt $ post "/backend/api/shoppinglist/entries.php" $ encodeFormState formState
  case r of
    Right res | res.status == (StatusCode 200) -> do
      -- If we POSTed successfully, reset the amount in the form.
      pure $ Just $ Ajax PostEntrySuccess
    -- If status is not 200, we expect an object of the form {error: String}
    Right res -> do
      log $ "Error: Expected status 200, received " <> (\(StatusCode n) -> show n) res.status <> " while posting entry."
      log $ "Response from server:"
      log res.response
      pure $ Just (Ajax PostEntryError)
    Left err -> do
      log $ show err
      pure $ Just $ Ajax PostEntryError


decodeCategories :: Json -> Either String (List Category)
decodeCategories r = do
  obj <- decodeJson r
  categories <- obj .? "categories"
  decodeJson categories

-- decodeErrorResponse :: Json -> Either String String
-- decodeErrorResponse r = do
--   obj <- decodeJson r
--   err <- obj .? "error"
--   decodeJson err

encodeFormState :: FormState -> Json
encodeFormState formState =
  "name" := formState.name
  ~> "category" := formState.category
  ~> jsonEmptyObject
