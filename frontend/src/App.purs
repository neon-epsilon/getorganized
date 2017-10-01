module App where

import Prelude
import Data.Maybe (Maybe (..))

import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Eff.Now (NOW)
import Control.Monad.Aff (delay)
import Data.Time.Duration (Milliseconds (..))
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
  FlashMessage String |
  UnFlashMessage Int |
  HoursOfWorkEvent HoursOfWork.Event


type State =
  { currentRoute :: Route
  , message :: Maybe Message
  , hoursOfWorkState :: HoursOfWork.State }

newtype Message = Message
  { messageText :: String
  , messageId :: Int }
  -- messageId is needed to correctly stop showing messages after a given time.

init :: State
init =
  { currentRoute : Home
  , message : Nothing
  , hoursOfWorkState : HoursOfWork.init }


-- The "forall eff" is important. Without it the effects in the main monad get
-- restricted which leads to a compiler error.
foldp :: forall eff. Event -> State
  -> EffModel State Event (ajax :: AJAX, console :: CONSOLE, dom :: DOM, now :: NOW | eff)
foldp (NavigateTo route) state = noEffects $ state { currentRoute = route }
foldp Init state =
  { state: state
  , effects: [ pure $ Just $ HoursOfWorkEvent HoursOfWork.Init ]}
foldp (FlashMessage s) state@{message} =
  { state: state { message = Just (Message {messageText : s, messageId: id}) }
  , effects: [ timeout ] }
  where
    id = case message of
      Nothing -> 0
      Just (Message {messageId}) -> messageId + 1
    timeout = do
      delay $ Milliseconds 5000.0
      pure $ Just $ UnFlashMessage id
foldp (UnFlashMessage id) state@{message} =
  noEffects $ state { message = newMessage }
  where
    newMessage = case message of
      Just (Message {messageId}) -> if messageId == id
        then Nothing
        else message
      _ -> message
foldp (HoursOfWorkEvent hoursOfWorkEvent) state@{hoursOfWorkState} = 
  { state: state {hoursOfWorkState = hoursOfWorkEffModel.state }
  , effects: effects }
  where
    hoursOfWorkEffModel = HoursOfWork.foldp hoursOfWorkEvent hoursOfWorkState
    hoursOfWorkEffects = map (map HoursOfWorkEvent) <$> hoursOfWorkEffModel.effects
    effects = case getAppEvent hoursOfWorkEvent of
      NoOp -> hoursOfWorkEffects
      UserMessage s -> [pure $ Just $ FlashMessage s] <> hoursOfWorkEffects



view :: State -> HTML Event
view s = do
  let message = case s.message of
                      Nothing -> "GetOrganized"
                      Just (Message { messageText }) -> messageText
  mapEvent NavigateTo $ menu message
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
