module Main where

import DOM (DOM)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Exception (EXCEPTION)
import Network.HTTP.Affjax (AJAX)
import Prelude ((<<<), bind, Unit)
import Pux (start, renderToDOM)
import Pux.Router (sampleUrl)
import Signal ((~>))
import Signal.Channel

import Routes (match, Route(..))
import App (Action(..), init, update, view)


main :: Eff (channel :: CHANNEL, dom :: DOM, err :: EXCEPTION, ajax :: AJAX ) Unit
main = do
  urlSignal <- sampleUrl
  let routeSignal = urlSignal ~> (PageView <<< match)

  inputChannel <- channel (PageView NotFound)
  let inputSignal = subscribe inputChannel

  app <- start
    { initialState: init
    , update: update
    , view: view
    , inputs: [inputSignal, routeSignal]
    }

  renderToDOM "#main" app.html

  send inputChannel (PageView Home)
  send inputChannel FetchData
