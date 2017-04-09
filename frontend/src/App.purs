module App where

import Data.Maybe (Maybe(..))

import Prelude (($), map, pure)
import Pux (EffModel, noEffects)
import Pux.DOM.HTML (HTML)
import Text.Smolder.HTML (div, h1)
import Text.Smolder.Markup (text)
import Network.HTTP.Affjax (AJAX)

import Routes (Route(..))
import Pages.Home as Home
import Pages.Calories as Calories
import Pages.HoursOfWork as HoursOfWork
import Pages.Spendings as Spendings
import Pages.ShoppingList as ShoppingList


data Event =
  PageView Route |
  FetchData |
  HoursOfWorkEvent HoursOfWork.Event


type State =
  { currentRoute :: Route
  , hoursOfWorkState :: HoursOfWork.State }

init :: State
init =
  { currentRoute: Home
  , hoursOfWorkState: HoursOfWork.init }


-- The "forall eff" is important. Without it the effects in the main monad get
-- restricted which leads to a compiler error.
foldp :: forall eff. Event -> State -> EffModel State Event (ajax :: AJAX | eff)
foldp (PageView route) state = noEffects $ state { currentRoute = route }
foldp FetchData state =
  { state: state
  , effects: [ pure $ Just $ HoursOfWorkEvent HoursOfWork.RequestCategories ]}
foldp (HoursOfWorkEvent hoursOfWorkEvent) state@{hoursOfWorkState} = 
  { state: state {hoursOfWorkState = newHoursOfWorkState}
  , effects: map (map (map HoursOfWorkEvent)) hoursOfWorkEffects }
  where
    hoursOfWorkEffModel = HoursOfWork.foldp hoursOfWorkEvent hoursOfWorkState
    newHoursOfWorkState = hoursOfWorkEffModel.state
    hoursOfWorkEffects = hoursOfWorkEffModel.effects


view :: State -> HTML Event
view { currentRoute: Home } =
  div $ Home.view
view { currentRoute: Calories } =
  div $ Calories.view
view { currentRoute: HoursOfWork, hoursOfWorkState } =
  div $ HoursOfWork.view hoursOfWorkState
view { currentRoute: Spendings } =
  div $ Spendings.view
view { currentRoute: ShoppingList } =
  div $ ShoppingList.view
view { currentRoute: NotFound } =
  h1 $ text "404, nix ist hier!"
