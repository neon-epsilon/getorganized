module Pages.HoursOfWork where

import Prelude (($), bind, discard, map, show, pure, (>=>), (<<<), const, (==), (<>), comparing)

import Data.Number (fromString)
import Data.List (List(..), (:), sortBy)
import Data.Either (Either(..), either)
import Data.Maybe (Maybe(..))

import Data.Formatter.DateTime (FormatterF (..), format)
import Data.Functor.Mu (Mu (..))
import Control.Comonad (extract)

import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Now (NOW, nowDateTime)
import Control.Monad.Aff (attempt, Aff)
import Control.Monad.Aff.Console (log, CONSOLE)

import Data.Argonaut (Json, class DecodeJson, decodeJson, (.?), (:=), (~>), jsonEmptyObject)
import Network.HTTP.Affjax (AJAX, get, post)
import Network.HTTP.StatusCode (StatusCode(..))

import Pux (EffModel, noEffects, onlyEffects)
import Pux.DOM.HTML (HTML)
import Pux.DOM.Events (DOMEvent, onChange, onSubmit, targetValue)

import DOM (DOM)
import DOM.Event.Event (preventDefault)

import Text.Smolder.HTML (h1, h2, img, ul, li, label)
import Text.Smolder.HTML.Attributes (src, value)
import Text.Smolder.Markup ((!), (#!), text)

import Pages.Components



data Event = Init
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
  | DateChange DOMEvent
  | AmountChange DOMEvent
  | CategoryChange DOMEvent
  | SetDate String



type State =
  { ajaxState :: AjaxState
  , categories :: List Category
  , formState :: FormState }


data AjaxState = NoOp
  | GettingCategories
  | PostingEntry
  | FatalError


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
  { date :: String
  , amount :: String
  , category :: String }


init :: State
init =
  { ajaxState : GettingCategories
  , categories : Nil
  , formState : initFormState }

initFormState :: FormState
initFormState =
  { date : ""
  , amount : ""
  , category: "" }



view :: State -> HTML Event
view { ajaxState, categories, formState } =
  container $ do
    smallBox $ do
      h1 $ text "Eingabe"
      h2 $ text "Arbeitszeit eingeben"
      customForm buttonText isActive #! onSubmit (Form <<< Submit) $ ul $ do
        li $ do
          label $ text "Datum:"
          dateInput ! value formState.date #! onChange (Form <<< DateChange)
        li $ do
          label $ text "Stunden:"
          numberInput ! value formState.amount #! onChange (Form <<< AmountChange)
        li $ do
          label $ text "Kategorie:"
          customSelect
            (map
            ( \(Category x) -> {value : x.category, text : x.category} )
            categories)
            ! value formState.category
            #! onChange (Form <<< CategoryChange)
    box $ do
      img ! src "/generated/hoursofwork/chart_7days.png"
      img ! src "/generated/hoursofwork/chart_progress.png"
  where
    buttonText = case ajaxState of
      NoOp -> "Speichern"
      GettingCategories -> "Lade..."
      PostingEntry -> "Sende Daten..."
      FatalError -> "Fehler"
    isActive = case ajaxState of
      NoOp -> true
      _ -> false



foldp :: forall eff. Event -> State
  -> EffModel State Event (ajax :: AJAX, console :: CONSOLE, dom :: DOM, now :: NOW | eff)
foldp Init state =
  { state : state
  , effects :
    [ do
      localeDateTime <- liftEff $ nowDateTime
      let dateTime = extract localeDateTime
      -- Formatter is a crazy functor fixpoint (Mu).
      -- Therefore we construct the format using the Mu constructer "In".
      -- Alternative:
      -- let dateString = unsafePartial $ formRight $ formatDateTime "YYYY-MM-DD" dateTime
      let isoFormat = In $ YearFull
                    $ In $ Placeholder "-"
                    $ In $ MonthTwoDigits
                    $ In $ Placeholder "-"
                    $ In $ DayOfMonthTwoDigits
                    $ In End
      let dateString = format isoFormat dateTime
      pure $ Just $ Form $ SetDate dateString
    , pure $ Just $ Ajax GetCategories
    ]
  }

foldp (Ajax GetCategories) state =
  { state: state { ajaxState = GettingCategories }
  , effects: [ getCategories ]
  }
-- | Receive categories and store them sorted by their priority value
-- | If the received list is empty, set ajaxState = FatalError as we
-- | cannot recover from this state without action on the server side.
foldp (Ajax (GetCategoriesSuccess categories)) state@{ formState } =
  noEffects $ case categories of
    ((Category x) : xs) -> state
      { ajaxState = NoOp
      , categories = sortBy (comparing (\(Category c) -> c.priority)) categories
      , formState = formState { category = x.category }
      }
    Nil -> state
      { ajaxState = FatalError }
foldp (Ajax GetCategoriesError) state =
  noEffects $ state
foldp (Ajax PostEntry) state =
  { state: state { ajaxState = PostingEntry }
  , effects: [ postEntry state.formState ]
  }
foldp (Ajax PostEntrySuccess) state@{ formState, ajaxState } =
  noEffects $ state
    { formState = formState { amount = "" }
    , ajaxState = NoOp }
foldp (Ajax PostEntryError) state =
  noEffects $ state

foldp (Form (Submit ev)) state =
  onlyEffects state [ do
    liftEff (preventDefault ev)
    pure $ Just $ Ajax PostEntry
    ]
foldp (Form (DateChange ev)) state@{ formState } =
  noEffects $ state { formState = formState { date = targetValue ev } }
foldp (Form (AmountChange ev)) state@{ formState } =
  noEffects $ state { formState = formState { amount = targetValue ev } }
foldp (Form (CategoryChange ev)) state@{ formState } =
  noEffects $ state { formState = formState { category = targetValue ev } }
foldp (Form (SetDate d)) state@{ formState } =
  noEffects $ state { formState = formState { date = d } }


getCategories :: forall eff. Aff (ajax :: AJAX, console :: CONSOLE | eff) (Maybe Event)
getCategories = do
  r <- attempt $ get "/backend/api/hoursofwork/categories.php"
  case r of
    Left err -> do
      log $ show err
      pure $ Just $ Ajax GetCategoriesError
    Right res | res.status == (StatusCode 200) -> do
      let categories = decodeCategories res.response
      either
        (log >=> const (pure $ Just $ Ajax GetCategoriesError))
        (pure <<< Just <<< Ajax <<< GetCategoriesSuccess)
        categories
    -- | If status is not 200, we expect an object of the form {error: String}
    Right res -> do
      log $ "Error: Expected status 200, received " <> (\(StatusCode n) -> show n) res.status <> " while fetching categories."
      let err = decodeErrorResponse res.response
      either log log err
      pure $ Just (Ajax GetCategoriesError)


postEntry :: forall eff. FormState -> Aff (ajax :: AJAX, console :: CONSOLE | eff) (Maybe Event)
postEntry formState = do
  r <- attempt $ post "/backend/api/hoursofwork/entries.php" $ encodeFormState formState
  case r of
    Left err -> do
      log $ show err
      pure $ Just $ Ajax PostEntryError
    Right res | res.status == (StatusCode 200) -> do
      -- If we POSTed successfully, reset the amount in the form.
      pure $ Just $ Ajax PostEntrySuccess
    -- If status is not 200, we expect an object of the form {error: String}
    Right res -> do
      log $ "Error: Expected status 200, received " <> (\(StatusCode n) -> show n) res.status <> " while fetching categories."
      let err = decodeErrorResponse res.response
      either log log err
      pure $ Just (Ajax PostEntryError)


decodeCategories :: Json -> Either String (List Category)
decodeCategories r = do
  obj <- decodeJson r
  categories <- obj .? "categories"
  decodeJson categories

decodeErrorResponse :: Json -> Either String String
decodeErrorResponse r = do
  obj <- decodeJson r
  err <- obj .? "error"
  decodeJson err

encodeFormState :: FormState -> Json
encodeFormState formState =
  "date" := formState.date
  ~> "amount" := fromString formState.amount
  ~> "category" := formState.category
  ~> jsonEmptyObject
