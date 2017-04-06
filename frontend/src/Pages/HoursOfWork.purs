module Pages.HoursOfWork where


import Control.Monad.Aff (attempt)
import Data.Argonaut (class DecodeJson, decodeJson, (.?))
import Data.Either (Either(Left, Right), either)
import Data.Maybe (Maybe(..))
import Network.HTTP.Affjax (AJAX, get)
import Prelude (($), bind, map, const, show, (<>), pure, (<<<))
import Pux (EffModel, noEffects)
-- import Pux.Html.Attributes as HA
-- import Pux.Html.Events as HE
-- import Pux.Html as H
-- import Pages.Components as C


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


-- view :: forall action. State -> H.Html action
-- view { dataState, categories } =
--   C.container
--     [ C.smallBox
--       [ C.h1 "Eingabe"
--       , C.h2 "Arbeitszeit eingeben"
--       , C.form "hoursofwork_input_form_submit"
--         [ [ C.label "Datum:"
--           , C.dateInput
--           ]
--         , [ C.label "Stunden:"
--           , C.numberInput
--           , C.formHint "Format: \\d+(.\\d\\d?)?"           ]
--         , [ C.label "Kategorie:"
--           , C.select "category"
--             (map
--             ( \(Category x) -> {value : show x.priority, text : x.category} )
--             categories)
--           ]
--         ]
--       ]
-- 
--     , C.box
--       [ C.img "/generated/hoursofwork/chart_7days.png"
--       , C.img "/generated/hoursofwork/chart_progress.png"
--       ]
--     ]
