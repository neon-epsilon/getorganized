module Main where


import Prelude

import DOM (DOM)

import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Now (NOW)
import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Eff.Exception (EXCEPTION)
import Network.HTTP.Affjax (AJAX)

import Control.Monad.Aff (launchAff, delay)
import Data.Time.Duration (Milliseconds (..))
import Control.Monad.Eff.Class (liftEff)

import Pux (start)
import Pux.Renderer.React (renderToDOM)

import Signal.Channel (CHANNEL, channel, subscribe, send)

import App (Event(..), init, foldp, view)



main :: Eff
  ( channel :: CHANNEL
  , dom :: DOM
  , exception :: EXCEPTION
  , ajax :: AJAX
  , console :: CONSOLE
  , now :: NOW
  ) Unit
main = do
  inputChannel <- channel Init
  let inputSignal = subscribe inputChannel

  app <- start
    { initialState: init
    , view
    , foldp
    , inputs: [inputSignal]
    }

  renderToDOM "#main" app.markup app.input

  -- void <<< launchAff $ do
  --   liftEff $ send inputChannel (FlashMessage "asdf")
  --   delay $ Milliseconds 4000.0
  --   liftEff $ send inputChannel (FlashMessage "fdsa")
