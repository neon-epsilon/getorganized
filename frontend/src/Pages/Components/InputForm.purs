module Pages.Components.InputForm where

import Prelude

import Data.Number (fromString, nan)
import Data.List (List (..), (:), sortBy)
import Data.Either (Either (..), either)
import Data.Maybe (Maybe (..), maybe, fromMaybe)

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
import Data.DateTime.Instant (Instant, unInstant, instant)
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
import Pages.Components.DeleteForm as DF


-- TODO: add "comment" field


instance appComponentEvent :: AppComp.ComponentEvent Event where
  getAppEvent (Ajax GetCategoriesError) = AppComp.UserMessage "Fehler beim Laden von Daten"
  getAppEvent (Ajax PostEntryError) = AppComp.UserMessage "Fehler beim Senden von Daten"
  getAppEvent (Ajax PostEntryError) = AppComp.UserMessage "Fehler beim Senden von Daten"
  getAppEvent _ = AppComp.NoOp


deleteFormEvent :: Event -> Maybe DF.Event
deleteFormEvent (DeleteForm (AddEntry entry)) = Just $ DF.External $ DF.AddEntry entry
deleteFormEvent (DeleteForm Reload) = Just $ DF.External $ DF.Reload
deleteFormEvent _ = Nothing



data Event =
    Init
  | Ajax AjaxEvent
  | Form FormEvent
  | UpdatePicture Instant
  | DeleteForm DeleteFormEvent

data AjaxEvent =
    GetCategories
  | GetCategoriesSuccess (List Category)
  | GetCategoriesError
  | PostEntry
  | PostEntrySuccess {id:: Int, timestamp:: Instant}
  | PostEntryError

data FormEvent =
    Submit DOMEvent
  | DateChange DOMEvent
  | CategoryChange DOMEvent
  | AmountChange DOMEvent
  | CommentChange DOMEvent
  | SetDate String

data DeleteFormEvent =
    AddEntry DF.Entry
  | Reload



type State =
  { categories :: List Category
  , ajaxState :: AjaxState
  , formState :: FormState }


newtype Category = Category
  { category :: String
  , priority :: Int }

instance decodeJsonCategory :: DecodeJson Category where
  decodeJson json = do
    obj <- decodeJson json
    category <- obj .? "category"
    priority <- obj .? "priority"
    pure $ Category { category: category, priority: priority }


data AjaxState =
    Idle
  | GettingCategories
  | PostingEntry


type FormState =
  { date :: String
  , category :: String
  , amount :: String
  , comment :: String }


init :: State
init =
  { categories : Nil
  , ajaxState : GettingCategories
  , formState : initFormState }

initFormState :: FormState
initFormState =
  { date : ""
  , category: ""
  , amount: ""
  , comment: "" }



view :: State -> HTML Event
view { ajaxState, categories, formState } = do
  h1 $ text "Eintrag eingeben"
  customForm buttonText isActive #! onSubmit (Form <<< Submit) $ ul $ do
    li $ do
      label $ text "Datum:"
      dateInput ! value formState.date #! onChange (Form <<< DateChange)
    li $ do
      label $ text "Menge:"
      numberInput ! value formState.amount #! onChange (Form <<< AmountChange)
    li $ do
      label $ text "Kategorie:"
      customSelect
        (map
        ( \(Category x) -> {value : x.category, text : x.category} )
        categories)
        ! value formState.category
        #! onChange (Form <<< CategoryChange)
    li $ do
      label $ text "Kommentar:"
      textInput ! value formState.comment #! onChange (Form <<< CommentChange)
  where
    buttonText = case ajaxState of
      Idle -> "Speichern"
      GettingCategories -> "Lade..."
      PostingEntry -> "Sende Daten..."
    isActive = case ajaxState of
      Idle -> true
      _ -> false



makeFoldp :: forall eff. String -> Event -> State
  -> EffModel State Event (ajax :: AJAX, console :: CONSOLE, dom :: DOM, now :: NOW | eff)
makeFoldp resourceName = foldp
  where
  foldp Init state =
    { state : state
    , effects :
      [ do
        localeDateTime <- liftEff $ nowDateTime
        let dateTime = extract localeDateTime
        -- Alternative:
        -- let dateString = unsafePartial $ fromRight $ formatDateTime "YYYY-MM-DD" dateTime
        let isoFormat =   YearFull
                        : Placeholder "-"
                        : MonthTwoDigits
                        : Placeholder "-"
                        : DayOfMonthTwoDigits
                        : Nil
        let dateString = format isoFormat dateTime
        pure $ Just $ Form $ SetDate dateString
      , pure $ Just $ Ajax GetCategories ]
    }

  foldp (Ajax GetCategories) state =
    { state: state { ajaxState = GettingCategories }
    , effects: [ getCategories resourceName ]
    }
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
    onlyEffects state [pure $ Just $ Ajax $ GetCategories]
  foldp (Ajax PostEntry) state =
    { state: state { ajaxState = PostingEntry }
    , effects: [ postEntry resourceName state.formState ]
    }
  foldp (Ajax (PostEntrySuccess {id, timestamp})) state@{formState} =
    { state: state
      { formState = formState { amount = "" }
      , ajaxState = Idle }
    , effects:
      [ pure $ Just $ DeleteForm $ AddEntry $
        DF.Entry { id: id, date: formState.date, category: formState.category, amount: fromMaybe nan $ fromString formState.amount }
      , pure $ Just $ UpdatePicture timestamp ] }
  foldp (Ajax PostEntryError) state =
    { state: state { ajaxState = Idle }
    , effects: [ pure $ Just $ DeleteForm Reload ] }

  foldp (Form (Submit ev)) state =
    onlyEffects state [ do
      liftEff (preventDefault ev)
      pure $ Just $ Ajax PostEntry
      ]
  foldp (Form (DateChange ev)) state@{ formState } =
    noEffects $ state { formState = formState { date = targetValue ev } }
  foldp (Form (CategoryChange ev)) state@{ formState } =
    noEffects $ state { formState = formState { category = targetValue ev } }
  foldp (Form (AmountChange ev)) state@{ formState } =
    noEffects $ state { formState = formState { amount = targetValue ev } }
  foldp (Form (CommentChange ev)) state@{ formState } =
    noEffects $ state { formState = formState { comment = targetValue ev } }
  foldp (Form (SetDate d)) state@{ formState } =
    noEffects $ state { formState = formState { date = d } }

  foldp (UpdatePicture _) state = noEffects state

  foldp (DeleteForm _) state = noEffects state


-- | Get categories. If there is a recoverable error, wait a second and retry.
-- | If no answer from server after ten seconds, retry.
-- | Otherwise success or fatal error.
getCategories :: forall eff. String -> Aff (ajax :: AJAX, console :: CONSOLE | eff) (Maybe Event)
getCategories resourceName = do
  maybeRes <- attemptWithTimeout 10000.0 (getWithoutCaching $ "/backend/api/" <> resourceName <> "/categories.php")
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


postEntry :: forall eff. String -> FormState -> Aff (ajax :: AJAX, console :: CONSOLE | eff) (Maybe Event)
postEntry resourceName formState = do
  maybeRes <- attemptWithTimeout 10000.0 $ post ("/backend/api/" <> resourceName <> "/entries.php") (encodeFormState formState)
  case maybeRes of
    Just (Right res) | res.status == (StatusCode 200) -> do
      -- If we POSTed successfully, get the id assigned to the new entry,
      -- reset the amount in the form and pass the new entry to the delete form.
      let psr = decodePostSuccessResponse =<< jsonParser res.response
      either
        -- If we do not get a valid id back it's a server error and thus fatal.
        (log >=> const (pure $ Just $ Ajax PostEntryError))
        (pure <<< Just <<< Ajax <<< PostEntrySuccess)
        psr
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
      log $ "Error: Request timed out while posting entries."
      pure $ Just $ Ajax PostEntryError



decodeCategories :: Json -> Either String (List Category)
decodeCategories r = do
  obj <- decodeJson r
  categories <- obj .? "categories"
  decodeJson categories

decodePostSuccessResponse :: Json -> Either String {id:: Int, timestamp:: Instant}
decodePostSuccessResponse r = do
  obj <- decodeJson r
  id <- obj .? "id"
  t <- obj .? "timestamp"
  case (instant (Milliseconds t)) of
    Nothing -> Left "Error: Timestamp received from server is out of range."
    Just timestamp -> Right {id, timestamp}

-- decodeErrorResponse :: Json -> Either String String
-- decodeErrorResponse r = do
--   obj <- decodeJson r
--   err <- obj .? "error"
--   decodeJson err

encodeFormState :: FormState -> Json
encodeFormState formState =
  "date" := formState.date
  ~> "category" := formState.category
  ~> "amount" := (fromMaybe nan $ fromString formState.amount)
  ~> "comment" := formState.comment
  ~> jsonEmptyObject
