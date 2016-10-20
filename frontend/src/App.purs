module App where

import Prelude ((<>), ($), show)
import Pux.Html (Html, div, h1, text)

import Routes (Route(..))
import Pages.Home as Home

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
page route = h1 [] [ text $ show route ]
