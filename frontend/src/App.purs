module App where

import Prelude (($), map, pure)
import Control.Monad.Eff.Console (CONSOLE)
import Data.Maybe (Maybe(..))

import DOM (DOM)
import Network.HTTP.Affjax (AJAX)

import Pux (EffModel, noEffects)
import Pux.DOM.HTML (HTML, mapEvent)
import Text.Smolder.HTML (div, h1)
import Text.Smolder.Markup (text)

import Routes (Route(..))
import Pages.Home as Home
import Pages.HoursOfWork as HoursOfWork
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
foldp :: forall eff. Event -> State -> EffModel State Event (ajax :: AJAX, console :: CONSOLE, dom :: DOM | eff)
foldp (PageView route) state = noEffects $ state { currentRoute = route }
foldp FetchData state =
  { state: state
  , effects: [ pure $ Just $ HoursOfWorkEvent $ HoursOfWork.Ajax HoursOfWork.RequestCategories ]}
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
  noPage
view { currentRoute: HoursOfWork, hoursOfWorkState } =
  div $ mapEvent HoursOfWorkEvent $ HoursOfWork.view hoursOfWorkState
view { currentRoute: Spendings } =
  noPage
view { currentRoute: ShoppingList } =
  div $ ShoppingList.view
view { currentRoute: NotFound } =
  noPage

noPage :: HTML Event
noPage = h1 $ text "404, nix ist hier."
