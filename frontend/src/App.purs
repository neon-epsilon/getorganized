module App where

import Pux.Html (Html, div, h1, text)

import Routes (Route(..))
import Pages.Home as Home
import Pages.Calories as Calories
import Pages.HoursOfWork as HoursOfWork
import Pages.Spendings as Spendings
import Pages.ShoppingList as ShoppingList

data Action = PageView Route

type State = { currentRoute :: Route }

init :: State
init = { currentRoute: Home }

update :: Action -> State -> State
update (PageView route) state = state { currentRoute = route }

view :: State -> Html Action
view state =
  div [] [ page state.currentRoute ]

page :: Route -> Html Action
page Home  = Home.view
page Calories = Calories.view
page HoursOfWork = HoursOfWork.view
page Spendings = Spendings.view
page ShoppingList = ShoppingList.view
page NotFound = h1 [] [ text "404, nix ist hier!"]
