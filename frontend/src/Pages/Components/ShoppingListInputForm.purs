module Pages.Components.ShoppingListInputForm where

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

import Utilities
import Pages.Components

import App.Component as AppComp
import Pages.Components.ShoppingListDeleteForm as DF



instance appComponentEvent :: AppComp.ComponentEvent Event where
  getAppEvent (Ajax GetCategoriesError) = AppComp.UserMessage "Fehler beim Laden von Daten"
  getAppEvent (Ajax PostEntryError) = AppComp.UserMessage "Fehler beim Senden von Daten"
  getAppEvent _ = AppComp.NoOp


deleteFormEvent :: Event -> Maybe DF.Event
deleteFormEvent (DeleteForm (AddEntry entry)) = Just $ DF.External $ DF.AddEntry entry
deleteFormEvent (DeleteForm Reload) = Just $ DF.External DF.Reload
deleteFormEvent _ = Nothing



data Event =
    Init
  | Ajax AjaxEvent
  | Form FormEvent
  | DeleteForm DeleteFormEvent

data AjaxEvent =
    GetCategories
  | GetCategoriesSuccess (List Category)
  | GetCategoriesError
  | PostEntry
  | PostEntrySuccess Int
  | PostEntryError

data FormEvent =
    Submit DOMEvent
  | NameChange DOMEvent
  | CategoryChange DOMEvent

data DeleteFormEvent =
    AddEntry DF.Entry
  | Reload



type State =
  { ajaxState :: AjaxState
  , categories :: List Category
  , formState :: FormState }

data AjaxState =
    Idle
  | GettingCategories
  | PostingEntry


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
  h1 $ text "Artikel eingeben"
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
      Idle -> "Speichern"
      GettingCategories -> "Lade..."
      PostingEntry -> "Sende Daten..."
    isActive = case ajaxState of
      Idle -> true
      _ -> false



foldp :: forall eff. Event -> State
  -> EffModel State Event (ajax :: AJAX, console :: CONSOLE, dom :: DOM, now :: NOW | eff)
foldp Init state =
  { state : state
  , effects : [ pure $ Just $ Ajax GetCategories ] }

foldp (Ajax GetCategories) state =
  { state: state { ajaxState = GettingCategories }
  , effects: [ getCategories ] }
-- | Receive categories and store them sorted by their priority value
-- | If the received list is empty, set ajaxState = Error as we
-- | cannot recover from this state without action on the server side.
foldp (Ajax (GetCategoriesSuccess categories)) state@{ formState } =
  case categories of
    ((Category x) : xs) -> noEffects $ state
      { ajaxState = Idle
      , categories = sortBy (comparing (\(Category c) -> c.priority)) categories
      , formState = formState { category = x.category }
      }
    Nil -> onlyEffects state [ do
      log "Error: Received empty list of categories from server."
      pure $ Just $ Ajax GetCategoriesError
      ]
foldp (Ajax GetCategoriesError) state =
  onlyEffects state [pure $ Just $ Ajax GetCategories]
foldp (Ajax PostEntry) state =
  { state: state { ajaxState = PostingEntry }
  , effects: [ postEntry state.formState ] }
foldp (Ajax (PostEntrySuccess id)) state@{ formState } =
  { state: state
    { formState = formState { name = "" }
    , ajaxState = Idle }
  , effects:
    [ pure $ Just $ DeleteForm $ AddEntry $
      DF.Entry { id: id, name: formState.name, category: formState.category } ] }
foldp (Ajax PostEntryError) state =
  { state: state { ajaxState = Idle }
  , effects: [ pure $ Just $ DeleteForm Reload ] }

foldp (Form (Submit ev)) state =
  onlyEffects state [ do
    liftEff (preventDefault ev)
    pure $ Just $ Ajax PostEntry ]
foldp (Form (NameChange ev)) state@{ formState } =
  noEffects $ state { formState = formState { name = targetValue ev } }
foldp (Form (CategoryChange ev)) state@{ formState } =
  noEffects $ state { formState = formState { category = targetValue ev } }

foldp (DeleteForm _) state = noEffects state


-- | Get categories. If there is a recoverable error, wait a second and retry.
-- | If no answer from server after ten seconds, retry.
getCategories :: forall eff. Aff (ajax :: AJAX, console :: CONSOLE | eff) (Maybe Event)
getCategories = do
  maybeRes <- attemptWithTimeout 10000.0 (getWithoutCaching "/backend/api/shoppinglist/categories.php")
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
      pure $ Just $ Ajax GetCategoriesError
    Just (Left err) -> do
      log $ show err
      delay $ Milliseconds 1000.0
      pure $ Just $ Ajax GetCategoriesError
    Nothing -> do
      log $ "Error: Request timed out while getting categories."
      pure $ Just $ Ajax GetCategoriesError


postEntry :: forall eff. FormState -> Aff (ajax :: AJAX, console :: CONSOLE | eff) (Maybe Event)
postEntry formState = do
  maybeRes <- attemptWithTimeout 10000.0 $ post "/backend/api/shoppinglist/entries.php" (encodeFormState formState)
  case maybeRes of
    Just (Right res) | res.status == (StatusCode 200) -> do
      -- If we POSTed successfully, get the id assigned to the new entry,
      -- reset the amount in the form and pass the new entry to the delete form.
      let id = decodeId =<< jsonParser res.response
      either
        -- If we do not get a valid id back it's a server error.
        (log >=> const (pure $ Just $ Ajax PostEntryError))
        (pure <<< Just <<< Ajax <<< PostEntrySuccess)
        id
    -- If status is not 200, it should be 50* because we assume that no client error 40* is possible.
    -- We expect an object of the form {error: String}.
    Just (Right res) -> do
      log $ "Error: Expected status 200, received " <> (\(StatusCode n) -> show n) res.status <> " while posting entry."
      log $ "Response from server:"
      log res.response
      pure $ Just (Ajax PostEntryError)
    -- Timed out or something.
    -- Reload entries in delete form as data integrity is no more guaranteed.
    Just (Left err) -> do
      log $ show err
      pure $ Just $ Ajax PostEntryError
    Nothing -> do
      log $ "Error: Request timed out while posting entry."
      pure $ Just $ Ajax PostEntryError


decodeCategories :: Json -> Either String (List Category)
decodeCategories r = do
  obj <- decodeJson r
  categories <- obj .? "categories"
  decodeJson categories

decodeId :: Json -> Either String Int
decodeId r = do
  obj <- decodeJson r
  obj .? "id"

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
