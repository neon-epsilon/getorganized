module Pages.HoursOfWork where

import Prelude (($), bind, map, show, pure, (>=>), (<<<), const, (==), (<>))
import Data.Either (Either(..), either)
import Data.Maybe (Maybe(..))

import Control.Monad.Aff.Console (log, CONSOLE)
import Control.Monad.Aff (attempt, Aff)

import Data.Argonaut (class DecodeJson, decodeJson, (.?), Json)
import Network.HTTP.Affjax (AJAX, get)
import Network.HTTP.StatusCode (StatusCode(..))

import Pux (EffModel, noEffects)

import Text.Smolder.HTML (h1, h2, img, ul, li, label)
import Text.Smolder.HTML.Attributes (src)
import Text.Smolder.Markup (Markup, (!), text)

import Pages.Components


data Event = RequestCategories
  | ReceiveCategories (Array Category)
  | FetchingError


data DataState = Fetching
  | HasData
  | Error

type State =
  { dataState :: DataState
  , categories :: Array Category }

newtype Category = Category
  { category :: String
  , priority :: Int }


init :: State
init =
  { dataState : Fetching
  , categories : [] }


foldp :: forall eff. Event -> State -> EffModel State Event (ajax :: AJAX, console :: CONSOLE | eff)
foldp FetchingError state =
  noEffects $ state { dataState = Error }
foldp (ReceiveCategories categories) state =
  noEffects $ state { dataState = HasData, categories = categories }
foldp RequestCategories state =
  { state: state { dataState = Fetching }
  , effects: [ fetchCategories ]
  }


view :: forall e. State -> Markup e
view { dataState, categories } =
  container $ do
    smallBox $ do
      h1 $ text "Eingabe"
      h2 $ text "Arbeitszeit eingeben"
      customForm "hoursofwork_input_form_submit" $ ul $ do
        li $ do
          label $ text "Datum:"
          dateInput
        li $ do
          label $ text "Stunden:"
          numberInput
        li $ do
          label $ text "Kategorie:"
          customSelect "category"
            (map
            ( \(Category x) -> {value : show x.priority, text : x.category} )
            categories)
    box $ do
      img ! src "/generated/hoursofwork/chart_7days.png"
      img ! src "/generated/hoursofwork/chart_progress.png"


fetchCategories :: forall eff. Aff (ajax :: AJAX, console :: CONSOLE | eff) (Maybe Event)
fetchCategories = do
  r <- attempt $ get "/backend/api/hoursofwork/categories.php"
  case r of
    Left err -> do
      log $ show err
      pure $ Just FetchingError
    Right res | res.status == (StatusCode 200) -> do
      let categories = decodeCategoriesResponse res.response
      either
        (log >=> const (pure $ Just FetchingError))
        (pure <<< Just <<< ReceiveCategories)
        categories
    -- | If status is not 200, we expect an object of the form {error: String}
    Right res -> do
      log $ "Error: Expected status 200, received " <> (\(StatusCode n) -> show n) res.status <> " while fetching categories."
      let err = decodeErrorResponse res.response
      either log log err
      pure $ Just FetchingError

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
