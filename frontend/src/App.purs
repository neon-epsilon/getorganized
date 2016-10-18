module RoutingExample.App where

import Prelude ((<>), ($), show)
import Pux.Html (Html, div, h1, text)

import RoutingExample.Routes (Route(..))

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
page route      = h1 [] [ text $ show route ]
