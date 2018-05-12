module Pages.StandardPage where

import Prelude

import Data.Maybe (Maybe(..))

import Control.Monad.Aff.Console (CONSOLE)
import Control.Monad.Eff.Now (NOW)
import Network.HTTP.Affjax (AJAX)
import DOM (DOM)

import Pux (EffModel)
import Pux.DOM.HTML (HTML, mapEvent)
import Text.Smolder.Markup ((!), text)
import Text.Smolder.HTML (img)
import Text.Smolder.HTML.Attributes (src)

import Pages.Components
import App.Component as AppComp
import Pages.Components.InputForm as IF
import Pages.Components.DeleteForm as DF



data Event =
    Init
  | InputFormEvent IF.Event
  | DeleteFormEvent DF.Event

instance appComponentEvent :: AppComp.ComponentEvent Event where
  getAppEvent (InputFormEvent ev) = AppComp.getAppEvent ev
  getAppEvent (DeleteFormEvent ev) = AppComp.getAppEvent ev
  getAppEvent _ = AppComp.NoOp



type State =
  { inputFormState :: IF.State 
  , deleteFormState :: DF.State
  }


init :: State
init =
  { inputFormState : IF.init
  , deleteFormState : DF.init
  }



makeView :: String -> State -> HTML Event
makeView resourceName = view
  where
  view { inputFormState, deleteFormState } =
    container $ do
      smallBox $ do
        mapEvent InputFormEvent $ IF.view inputFormState
        mapEvent DeleteFormEvent $ DF.view deleteFormState
      box $ do
        img ! src ("/generated/" <> resourceName <> "/chart_7days.png")
        img ! src ("/generated/" <> resourceName <> "/chart_progress.png")



makeFoldp :: forall eff. String -> Event -> State
  -> EffModel State Event (ajax :: AJAX, console :: CONSOLE, dom :: DOM, now :: NOW | eff)
makeFoldp resourceName = foldp
  where
  foldp Init state =
    { state : state
    , effects :
      [ pure $ Just $ InputFormEvent IF.Init
      , pure $ Just $ DeleteFormEvent DF.Init
      ]
    }
  foldp (InputFormEvent ev) state@{inputFormState} =
    { state: state { inputFormState = inputFormEffModel.state }
    , effects: effects
    }
    where
      inputFormEffModel = (IF.makeFoldp resourceName) ev inputFormState
      inputFormEffects = map (map InputFormEvent) <$> inputFormEffModel.effects
      deleteFormEvent = DF.External $ DF.getExternalEvent ev
      effects = [pure $ Just $ DeleteFormEvent deleteFormEvent] <> inputFormEffects
  foldp (DeleteFormEvent ev) state@{deleteFormState} =
    { state: state { deleteFormState = deleteFormEffModel.state }
    , effects: map (map DeleteFormEvent) <$> deleteFormEffModel.effects
    }
    where
      deleteFormEffModel = (DF.makeFoldp resourceName) ev deleteFormState
