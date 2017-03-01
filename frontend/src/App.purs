module App where

import Prelude (($), map, pure)
import Pux (EffModel, noEffects)
import Pux.Html (Html, div, h1, text)
import Network.HTTP.Affjax (AJAX)

import Routes (Route(..))
import Pages.Home as Home
import Pages.Calories as Calories
import Pages.HoursOfWork as HoursOfWork
import Pages.Spendings as Spendings
import Pages.ShoppingList as ShoppingList


data Action =
  PageView Route |
  FetchData |
  HoursOfWorkAction HoursOfWork.Action


type State =
  { currentRoute :: Route
  , hoursOfWorkState :: HoursOfWork.State }

init :: State
init =
  { currentRoute: Home
  , hoursOfWorkState: HoursOfWork.init }


-- The "forall eff" is important. Without it the effects in the main monad get
-- restricted which leads to a compiler error.
update :: forall eff. Action -> State -> EffModel State Action (ajax :: AJAX | eff)
update (PageView route) state = noEffects $ state { currentRoute = route }
update FetchData state =
  { state: state
  , effects: [ pure (HoursOfWorkAction HoursOfWork.RequestCategories) ]}
update (HoursOfWorkAction hoursOfWorkAction) state@{hoursOfWorkState} = 
  { state: state {hoursOfWorkState = newHoursOfWorkState}
  , effects: map (map HoursOfWorkAction) hoursOfWorkEffects }
  where
    hoursOfWorkEffModel = HoursOfWork.update hoursOfWorkAction hoursOfWorkState
    newHoursOfWorkState = hoursOfWorkEffModel.state
    hoursOfWorkEffects = hoursOfWorkEffModel.effects


view :: State -> Html Action
view { currentRoute: Home } =
  div [] [ Home.view ]
view { currentRoute: Calories } =
  div [] [ Calories.view ]
view { currentRoute: HoursOfWork, hoursOfWorkState } =
  div [] [ HoursOfWork.view  hoursOfWorkState ]
view { currentRoute: Spendings } =
  div [] [ Spendings.view ]
view { currentRoute: ShoppingList } =
  div [] [ ShoppingList.view ]
view { currentRoute: NotFound } =
  h1 [] [ text "404, nix ist hier!" ]
