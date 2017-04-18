module Pages.HoursOfWork where

import Prelude (($), bind, map, show, pure, (>=>), (<<<), const, (==), (<>), comparing, otherwise)
import Global (readFloat, isFinite)

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

import Pux (EffModel, noEffects)
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

data AjaxEvent = AjaxError
  | RequestCategories
  | ReceiveCategories (List Category)

data FormEvent = Submit DOMEvent
  | DateChange DOMEvent
  | AmountChange DOMEvent
  | CategoryChange DOMEvent
  | SetDate String



type State =
  { initState :: InitState
  , categories :: List Category
  , formState :: FormState }


data InitState = Initializing
  | Getting
  | Initialized
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
  { date :: String
  , amount :: String
  , category :: String }


-- | This component will need a distinct init event to perform
-- | effectful initialization (fetching categories, finding out current date).
init :: State
init =
  { initState : Initializing
  , categories : Nil
  , formState : initFormState }

initFormState :: FormState
initFormState =
  { date : ""
  , amount : "0.0"
  , category: "" }



view :: State -> HTML Event
view { initState, categories, formState } =
  container $ do
    smallBox $ do
      h1 $ text "Eingabe"
      h2 $ text "Arbeitszeit eingeben"
      customForm #! onSubmit (Form <<< Submit) $ ul $ do
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
    , pure $ Just $ Ajax RequestCategories
    ]
  }

foldp (Ajax AjaxError) state =
  noEffects $ state { initState = Error }
-- Receive categories and store them sorted by their priority value
foldp (Ajax (ReceiveCategories categories)) state@{ formState } =
  noEffects $ case categories of
    ((Category x) : xs) -> state
      { initState = Initialized
      , categories = sortBy (comparing (\(Category c) -> c.priority)) categories
      , formState = formState { category = x.category }
      }
    Nil -> state
      { initState = Error }
foldp (Ajax RequestCategories) state =
  { state: state { initState = Getting }
  , effects: [ getCategories ]
  }

foldp (Form (Submit ev)) state =
  { state: state
  , effects: [ do
    liftEff (preventDefault ev)
    postEntry state.formState
    ]
  }
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
      pure $ Just $ Ajax AjaxError
    Right res | res.status == (StatusCode 200) -> do
      let categories = decodeCategories res.response
      either
        (log >=> const (pure $ Just $ Ajax AjaxError))
        (pure <<< Just <<< Ajax <<< ReceiveCategories)
        categories
    -- | If status is not 200, we expect an object of the form {error: String}
    Right res -> do
      log $ "Error: Expected status 200, received " <> (\(StatusCode n) -> show n) res.status <> " while fetching categories."
      let err = decodeErrorResponse res.response
      either log log err
      pure $ Just (Ajax AjaxError)


postEntry :: forall eff. FormState -> Aff (ajax :: AJAX, console :: CONSOLE | eff) (Maybe Event)
postEntry formState = do
  r <- attempt $ post "/backend/api/hoursofwork/entries.php" $ encodeFormState formState
  case r of
    Left err -> do
      log $ show err
      pure $ Just $ Ajax AjaxError
    Right res | res.status == (StatusCode 200) -> do
      pure Nothing
    -- | If status is not 200, we expect an object of the form {error: String}
    Right res -> do
      log $ "Error: Expected status 200, received " <> (\(StatusCode n) -> show n) res.status <> " while fetching categories."
      let err = decodeErrorResponse res.response
      either log log err
      pure $ Just (Ajax AjaxError)


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
  ~> "amount" := readFloat formState.amount
  ~> "category" := formState.category
  ~> jsonEmptyObject
