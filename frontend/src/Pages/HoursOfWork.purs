module Pages.HoursOfWork where


import Control.Monad.Aff (attempt)
import Data.Argonaut (class DecodeJson, decodeJson, (.?))
import Data.Either (Either(Left, Right), either)
import Data.Maybe (Maybe(..))
import Network.HTTP.Affjax (AJAX, get)
import Prelude (($), bind, map, show, pure, (<<<))

import Pux (EffModel, noEffects)

import Text.Smolder.HTML (h1, h2, img, ul, li, label)
import Text.Smolder.HTML.Attributes (src)
import Text.Smolder.Markup (Markup, (!), text)

import Pages.Components


data Event = RequestCategories | ReceiveCategories (Either String (Array Category))


data DataState = Fetching | HasData | Error

newtype Category = Category
  { category :: String
  , priority :: Int }

instance decodeJsonCategory :: DecodeJson Category where
  decodeJson json = do
    obj <- decodeJson json
    category <- obj .? "category"
    priority <- obj .? "priority"
    pure $ Category { category: category, priority: priority }

type State =
  { dataState :: DataState
  , categories :: Array Category }

init :: State
init =
  { dataState : HasData
  , categories : [] }


foldp :: forall eff. Event -> State -> EffModel State Event (ajax :: AJAX | eff)
foldp (ReceiveCategories (Left err)) state =
  noEffects $ state { dataState = Error }
foldp (ReceiveCategories (Right categories)) state =
  noEffects $ state { dataState = HasData, categories = categories }
foldp RequestCategories state =
  { state: state { dataState = Fetching }
  , effects: [ do
      res <- attempt $ get "/backend/api/hoursofwork/categories.php"
      let decode r = decodeJson r.response :: Either String (Array Category)
      let categories = either (Left <<< show) decode res
      pure $ Just $ ReceiveCategories categories
    ]
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
