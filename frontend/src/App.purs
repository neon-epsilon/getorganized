module App where

import Pux.Html (Html, div, h1, text)

import Routes (Route(..))
import Pages.Home as Home
import Pages.Calories as Calories
import Pages.HoursOfWork as HoursOfWork
import Pages.Spendings as Spendings
import Pages.ShoppingList as ShoppingList


data Action =
  PageView Route


type State =
  { currentRoute :: Route
  , hoursOfWorkState :: HoursOfWork.State }

init :: State
init =
  { currentRoute: Home
  , hoursOfWorkState: HoursOfWork.init }


update :: Action -> State -> State
update (PageView route) state = state { currentRoute = route }


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
