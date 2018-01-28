module Pages.ShoppingList where

import Prelude

import Data.Maybe (Maybe(..))

import Control.Monad.Aff.Console (CONSOLE)
import Control.Monad.Eff.Now (NOW)
import Network.HTTP.Affjax (AJAX)
import DOM (DOM)

import Pux (EffModel)
import Pux.DOM.HTML (HTML, mapEvent)

import Pages.Components
import App.Component as AppComp
import Pages.InputForm as IF



data Event =
    Init
  | InputFormEvent IF.Event

instance appComponentEvent :: AppComp.ComponentEvent Event where
  getAppEvent (InputFormEvent ev) = AppComp.getAppEvent ev
  getAppEvent _ = AppComp.NoOp



type State =
  { inputFormState :: IF.State }


init :: State
init =
  { inputFormState : IF.init }



view :: State -> HTML Event
view { inputFormState } =
  container $ do
    mapEvent InputFormEvent $ IF.view inputFormState


foldp :: forall eff. Event -> State
  -> EffModel State Event (ajax :: AJAX, console :: CONSOLE, dom :: DOM, now :: NOW | eff)
foldp Init state =
  { state : state
  , effects : [ pure $ Just $ InputFormEvent IF.Init ]
  }
foldp (InputFormEvent ev) state@{inputFormState} =
  { state: state { inputFormState = inputFormEffModel.state }
  , effects: map (map InputFormEvent) <$> inputFormEffModel.effects
  }
  where
    inputFormEffModel = IF.foldp ev inputFormState
