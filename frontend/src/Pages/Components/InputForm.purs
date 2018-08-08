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



instance appComponentEvent :: AppComp.ComponentEvent Event where
  getAppEvent (Ajax GetCategoriesFatalError) = AppComp.UserMessage "Fehler beim Laden von Daten"
  getAppEvent (Ajax PostEntryError) = AppComp.UserMessage "Fehler beim Senden von Daten"
  getAppEvent (Ajax PostEntryFatalError) = AppComp.UserMessage "Fehler beim Senden von Daten"
  getAppEvent _ = AppComp.NoOp


instance deleteFormEvent :: DF.DeleteFormEventClass Event where
  getExternalEvent (DeleteForm (AddEntry entry)) = DF.AddEntry entry
  getExternalEvent (DeleteForm Reload) = DF.Reload
  getExternalEvent _ = DF.NoOp



newtype TimeStamp = TimeStamp Number



data Event =
    Init
  | Ajax AjaxEvent
  | ReloadPicture TimeStamp
  | Form FormEvent
  | DeleteForm DeleteFormEvent

data AjaxEvent =
    GetCategories
  | GetCategoriesSuccess (List Category)
  | GetCategoriesFatalError
  | PostEntry
  | PostEntrySuccess {id:: Int, timestamp:: TimeStamp}
  | PostEntryError
  | PostEntryFatalError

data FormEvent =
    Submit DOMEvent
  | DateChange DOMEvent
  | CategoryChange DOMEvent
  | AmountChange DOMEvent
  | SetDate String

data DeleteFormEvent =
    AddEntry DF.Entry
  | Reload



type State =
  { categories :: List Category
  , ajaxState :: AjaxState
  , pictureReloadState :: PictureReloadState
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
  | Error


data PictureReloadState =
    UpToDate
  | Loading TimeStamp


type FormState =
  { date :: String
  , category :: String
  , amount :: String }


init :: State
init =
  { categories : Nil
  , ajaxState : GettingCategories
  , pictureReloadState : UpToDate
  , formState : initFormState }

initFormState :: FormState
initFormState =
  { date : ""
  , category: ""
  , amount: "" }



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
  where
    buttonText = case ajaxState of
      Idle -> "Speichern"
      GettingCategories -> "Lade..."
      PostingEntry -> "Sende Daten..."
      Error -> "Fehler"
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
        pure $ Just $ Ajax GetCategoriesFatalError
        ]
  foldp (Ajax GetCategoriesFatalError) state =
    noEffects $ state { ajaxState = Error }
  foldp (Ajax PostEntry) state =
    { state: state { ajaxState = PostingEntry }
    , effects: [ postEntry resourceName state.formState ]
    }
  foldp (Ajax (PostEntrySuccess {id, timestamp})) state@{ formState, pictureReloadState } =
    { state: state
      { formState = formState { amount = "" }
      , ajaxState = Idle
      , pictureReloadState = Loading $ timestamp
      }
    , effects:
      [ pure $ Just $ DeleteForm $ AddEntry $
        DF.Entry { id: id, date: formState.date, category: formState.category, amount: fromMaybe nan $ fromString formState.amount }
      , pure $ Just $ ReloadPicture $ timestamp
      ]
    }
  foldp (Ajax PostEntryError) state =
    { state: state { ajaxState = Idle }
    , effects: [ pure $ Just $ DeleteForm Reload ]
    }
  foldp (Ajax PostEntryFatalError) state =
    noEffects $ state { ajaxState = Error }

  foldp (ReloadPicture (TimeStamp t)) state@{pictureReloadState} =
    case pictureReloadState of
      Loading (TimeStamp l) | l > t -> noEffects state
      -- If l > t, a newer ReloadPicture must have been triggered in the meantiime.
      _ -> noEffects state -- TODO

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
  foldp (Form (SetDate d)) state@{ formState } =
    noEffects $ state { formState = formState { date = d } }

  foldp (DeleteForm _) state = noEffects state


-- | Get categories. If there is a recoverable error, wait a second and retry.
-- | If no answer from server after ten seconds, retry.
-- | Otherwise success or fatal error.
getCategories :: forall eff. String -> Aff (ajax :: AJAX, console :: CONSOLE | eff) (Maybe Event)
getCategories resourceName = do
  maybeRes <- attemptWithTimeout 10000.0 (get $ "/backend/api/" <> resourceName <> "/categories.php")
  case maybeRes of
    Just (Right res) | res.status == (StatusCode 200) -> do
      let categories = decodeCategories =<< jsonParser res.response
      either
        (log >=> const (pure $ Just $ Ajax GetCategoriesFatalError))
        (pure <<< Just <<< Ajax <<< GetCategoriesSuccess)
        categories
    -- | If status is not 200, we expect an object of the form {error: String}
    Just (Right res) -> do
      log $ "Error: Expected status 200, received " <> (\(StatusCode n) -> show n) res.status <> " while fetching categories."
      log $ "Response from server:"
      log res.response
      pure $ Just (Ajax GetCategoriesFatalError)
    Just (Left err) -> do
      log $ show err
      delay $ Milliseconds 1000.0
      pure $ Just $ Ajax GetCategories
    Nothing -> do
      log $ "Error: Request timed out while getting categories."
      pure $ Just $ Ajax GetCategories


postEntry :: forall eff. String -> FormState -> Aff (ajax :: AJAX, console :: CONSOLE | eff) (Maybe Event)
postEntry resourceName formState = do
  r <- attempt $ (post $ "/backend/api/" <> resourceName <> "/entries.php") $ encodeFormState formState
  --TODO: Attempt with timout. In the case when an attempt was timed out we need to check 
  --      integrity of data. I.e.: reload entries.
  case r of
    Right res | res.status == (StatusCode 200) -> do
      -- If we POSTed successfully, get the id assigned to the new entry,
      -- reset the amount in the form and pass the new entry to the delete form.
      let psr = decodePostSuccessResponse =<< jsonParser res.response
      either
        -- If we do not get a valid id back it's a server error and thus fatal.
        (log >=> const (pure $ Just $ Ajax PostEntryFatalError))
        (pure <<< Just <<< Ajax <<< PostEntrySuccess)
        psr
    -- If status is not 200, it should be 50* because we assume that no client error 40* is possible.
    -- Therefore, this error is fatal.
    -- We expect an object of the form {error: String}.
    Right res -> do
      log $ "Error: Expected status 200, received " <> (\(StatusCode n) -> show n) res.status <> " while posting entry."
      log $ "Response from server:"
      log res.response
      pure $ Just (Ajax PostEntryFatalError)
    -- Timed out or something. Possibly no fatal error.
    -- Reload entries in delete form as data integrity is no more guaranteed.
    Left err -> do
      log $ show err
      pure $ Just $ Ajax PostEntryError


-- TODO
getTimeStamp :: forall eff. String -> Aff (ajax :: AJAX, console :: CONSOLE | eff) (Maybe Event)
getTimeStamp resourceName = do
  maybeRes <- attemptWithTimeout 10000.0 (get $ "/generated/" <> resourceName <> "/timestamp")
  case maybeRes of
    Just (Right res) | res.status == (StatusCode 200) -> do
      let timestamp = fromString res.response
      maybe
        (pure Nothing)
        (const $ pure Nothing)
        timestamp
    -- | If status is not 200, we expect an object of the form {error: String}
    Just (Right res) -> do
      log $ "Error: Expected status 200, received " <> (\(StatusCode n) -> show n) res.status <> " while fetching categories."
      log $ "Response from server:"
      log res.response
      pure $ Nothing
    Just (Left err) -> do
      log $ show err
      delay $ Milliseconds 1000.0
      pure $ Nothing
    Nothing -> do
      log $ "Error: Request timed out while getting categories."
      pure $ Nothing


decodeCategories :: Json -> Either String (List Category)
decodeCategories r = do
  obj <- decodeJson r
  categories <- obj .? "categories"
  decodeJson categories

decodePostSuccessResponse :: Json -> Either String {id:: Int, timestamp:: TimeStamp}
decodePostSuccessResponse r = do
  obj <- decodeJson r
  id <- obj .? "id"
  t <- obj .? "timestamp"
  pure {id, timestamp: TimeStamp t}

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
  ~> jsonEmptyObject
