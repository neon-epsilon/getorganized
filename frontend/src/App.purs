module App where

import Prelude
import Data.Maybe (Maybe (..))

import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Eff.Now (NOW)
import DOM (DOM)
import Network.HTTP.Affjax (AJAX)

import Pux (EffModel, noEffects)
import Pux.DOM.HTML (HTML, mapEvent)
import Text.Smolder.HTML (h1)
import Text.Smolder.Markup (text)

import App.Component
import Menu (Route (..), menu)
import Pages.Home as Home
import Pages.HoursOfWork as HoursOfWork
import Pages.ShoppingList as ShoppingList



data Event =
  Init |
  NavigateTo Route |
  SetMessage String |
  HoursOfWorkEvent HoursOfWork.Event


type State =
  { currentRoute :: Route
  , messageText :: Maybe String
  , hoursOfWorkState :: HoursOfWork.State }

init :: State
init =
  { currentRoute : Home
  , messageText : Nothing
  , hoursOfWorkState : HoursOfWork.init }


-- The "forall eff" is important. Without it the effects in the main monad get
-- restricted which leads to a compiler error.
foldp :: forall eff. Event -> State
  -> EffModel State Event (ajax :: AJAX, console :: CONSOLE, dom :: DOM, now :: NOW | eff)
foldp (NavigateTo route) state = noEffects $ state { currentRoute = route }
foldp Init state =
  { state: state
  , effects: [ pure $ Just $ HoursOfWorkEvent $ HoursOfWork.Init ]}
foldp (SetMessage s) state =
  noEffects $ state { messageText = Just s }
foldp (HoursOfWorkEvent hoursOfWorkEvent) state@{hoursOfWorkState} = 
  { state: state {hoursOfWorkState = hoursOfWorkEffModel.state }
  , effects: effects }
  where
    hoursOfWorkEffModel = HoursOfWork.foldp hoursOfWorkEvent hoursOfWorkState
    hoursOfWorkEffects = map (map HoursOfWorkEvent) <$> hoursOfWorkEffModel.effects
    effects = case getAppEvent hoursOfWorkEvent of
      NoOp -> hoursOfWorkEffects
      UserMessage s -> [pure $ Just $ SetMessage s] <> hoursOfWorkEffects



view :: State -> HTML Event
view s = do
  let messageText = case s.messageText of
                      Nothing -> "GetOrganized"
                      Just msg -> msg
  mapEvent NavigateTo $ menu messageText
  viewContainer s

viewContainer :: State -> HTML Event
viewContainer { currentRoute: Home } =
  Home.view
viewContainer { currentRoute: Calories } =
  noPage
viewContainer { currentRoute: HoursOfWork, hoursOfWorkState } = 
  mapEvent HoursOfWorkEvent $ HoursOfWork.view hoursOfWorkState
viewContainer { currentRoute: Spendings } =
  noPage
viewContainer { currentRoute: ShoppingList } =
  ShoppingList.view

noPage :: HTML Event
noPage = do
  h1 $ text "404, nix ist hier."
