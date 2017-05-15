module App where

import Prelude (($), map, discard, pure)
import Data.Maybe (Maybe(..))

import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Eff.Now (NOW)
import DOM (DOM)
import Network.HTTP.Affjax (AJAX)

import Pux (EffModel, noEffects)
import Pux.DOM.HTML (HTML, mapEvent)
import Text.Smolder.HTML (h1)
import Text.Smolder.Markup (text)

import Menu (Route (..), menu)
import Pages.Home as Home
import Pages.HoursOfWork as HoursOfWork
import Pages.ShoppingList as ShoppingList



data Event =
  Init |
  NavigateTo Route |
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
foldp :: forall eff. Event -> State
  -> EffModel State Event (ajax :: AJAX, console :: CONSOLE, dom :: DOM, now :: NOW | eff)
foldp (NavigateTo route) state = noEffects $ state { currentRoute = route }
foldp Init state =
  { state: state
  , effects: [ pure $ Just $ HoursOfWorkEvent $ HoursOfWork.Init ]}
foldp (HoursOfWorkEvent hoursOfWorkEvent) state@{hoursOfWorkState} = 
  { state: state {hoursOfWorkState = newHoursOfWorkState}
  , effects: map (map (map HoursOfWorkEvent)) hoursOfWorkEffects }
  where
    hoursOfWorkEffModel = HoursOfWork.foldp hoursOfWorkEvent hoursOfWorkState
    newHoursOfWorkState = hoursOfWorkEffModel.state
    hoursOfWorkEffects = hoursOfWorkEffModel.effects



view :: State -> HTML Event
view { currentRoute: Home } = do
  page $ Home.view
view { currentRoute: Calories } =
  noPage
view { currentRoute: HoursOfWork, hoursOfWorkState } = do
  page $ mapEvent HoursOfWorkEvent $ HoursOfWork.view hoursOfWorkState
view { currentRoute: Spendings } =
  noPage
view { currentRoute: ShoppingList } = do
  page $ ShoppingList.view

page :: HTML Event -> HTML Event
page h = do
  mapEvent NavigateTo $ menu
  h

noPage :: HTML Event
noPage = do
  mapEvent NavigateTo $ menu
  h1 $ text "404, nix ist hier."
