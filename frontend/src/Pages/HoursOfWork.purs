module Pages.HoursOfWork where

import Prelude (($), bind, map, show, pure, (>>=), (>=>), (<<<), const, (==), (<>), comparing)
import Data.Array (sortBy)
import Data.Either (Either(..), either)
import Data.Maybe (Maybe(..))

import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Aff.Console (log, CONSOLE)
import Control.Monad.Aff (attempt, Aff)

import Data.Argonaut (class DecodeJson, decodeJson, (.?), Json)
import Network.HTTP.Affjax (AJAX, get)
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


data Event = Ajax AjaxEvent
  | Form FormEvent

data AjaxEvent = AjaxError
  | RequestCategories
  | ReceiveCategories (Array Category)

data FormEvent = Submit DOMEvent
  | DateChange DOMEvent
  | AmountChange DOMEvent
  | CategoryChange DOMEvent


type State =
  { ajaxState :: AjaxState
  , categories :: Array Category
  , formState :: FormState }

data AjaxState = Initializing
  | Getting
  | HasData
  | Error

newtype Category = Category
  { category :: String
  , priority :: Int }

type FormState =
  { date :: String
  , amount :: String
  , category :: String }


-- | this component will need a distinct init event to perform
-- | effectful initialization (fetching categories, finding out current date)
init :: State
init =
  { ajaxState : Initializing
  , categories : []
  , formState : initFormState }

initFormState :: FormState
initFormState = 
  { date : "1970-01-01"
  , amount : "0.0"
  , category: "Uni" }


foldp :: forall eff. Event -> State -> EffModel State Event (ajax :: AJAX, console :: CONSOLE, dom :: DOM | eff)
foldp (Ajax AjaxError) state =
  noEffects $ state { ajaxState = Error }
-- | Receive categories and store them sorted by their priority value
foldp (Ajax (ReceiveCategories categories)) state =
  noEffects $ state
    { ajaxState = HasData
    , categories = sortBy (comparing (\(Category x) -> x.priority)) categories
    }
foldp (Ajax RequestCategories) state =
  { state: state { ajaxState = Getting }
  , effects: [ fetchCategories ]
  }
foldp (Form (DateChange ev)) state@{ formState } =
  noEffects $ state { formState = formState {date = targetValue ev} }
foldp (Form (AmountChange ev)) state@{ formState } =
  noEffects $ state { formState = formState {amount = targetValue ev} }
foldp (Form (CategoryChange ev)) state@{ formState } =
  noEffects $ state { formState = formState {category = targetValue ev} }
foldp (Form (Submit ev)) state =
  { state: state
  , effects: [ liftEff (preventDefault ev) >>= const (pure Nothing) ]
  }


view :: State -> HTML Event
view { ajaxState, categories, formState } =
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


fetchCategories :: forall eff. Aff (ajax :: AJAX, console :: CONSOLE | eff) (Maybe Event)
fetchCategories = do
  r <- attempt $ get "/backend/api/hoursofwork/categories.php"
  case r of
    Left err -> do
      log $ show err
      pure $ Just $ Ajax AjaxError
    Right res | res.status == (StatusCode 200) -> do
      let categories = decodeCategoriesResponse res.response
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

  where
    decodeCategoriesResponse :: Json -> Either String (Array Category)
    decodeCategoriesResponse r = do
      obj <- decodeJson r
      categories <- obj .? "categories"
      decodeJson categories

    decodeErrorResponse :: Json -> Either String String
    decodeErrorResponse r = do
      obj <- decodeJson r
      err <- obj .? "error"
      decodeJson err


instance decodeJsonCategory :: DecodeJson Category where
  decodeJson json = do
    obj <- decodeJson json
    category <- obj .? "category"
    priority <- obj .? "priority"
    pure $ Category { category: category, priority: priority }
