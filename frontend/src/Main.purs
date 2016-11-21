module Main where

import Prelude ((<<<), bind)
import Pux (start, fromSimple, renderToDOM)
import Pux.Router (sampleUrl)
import Signal ((~>))
import Signal.Channel

import Routes (match, Route(..))
import App (Action(..), init, update, view)

main = do
  urlSignal <- sampleUrl
  let routeSignal = urlSignal ~> (PageView <<< match)

  inputChannel <- channel (PageView NotFound)
  let inputSignal = subscribe inputChannel

  app <- start
    { initialState: init
    , update: fromSimple update
    , view: view
    , inputs: [inputSignal, routeSignal]
    }

  renderToDOM "#main" app.html

  send inputChannel (PageView Home)
