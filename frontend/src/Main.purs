module Main where


import Prelude (Unit, bind)

import DOM (DOM)

import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Now (NOW)
import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Eff.Exception (EXCEPTION)
import Network.HTTP.Affjax (AJAX)

import Pux (start)
import Pux.Renderer.React (renderToDOM)

import Signal.Channel

import App (Event(..), init, foldp, view)



main :: Eff
  ( channel :: CHANNEL
  , dom :: DOM
  , err :: EXCEPTION
  , ajax :: AJAX
  , console :: CONSOLE
  , now :: NOW
  ) Unit
main = do
  inputChannel <- channel (Init)
  let inputSignal = subscribe inputChannel

  app <- start
    { initialState: init
    , view
    , foldp
    , inputs: [inputSignal]
    }

  renderToDOM "#main" app.markup app.input

  send inputChannel Init
