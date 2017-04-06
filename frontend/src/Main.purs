module Main where

import DOM (DOM)
import DOM.HTML (window)
import DOM.HTML.Types (HISTORY)
import Control.Bind (bind, (=<<))
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Exception (EXCEPTION)
import Network.HTTP.Affjax (AJAX)
import Prelude ((<<<), bind, Unit)
import Pux (start)
import Pux.Renderer.React (renderToDOM)
import Pux.DOM.History (sampleURL)
import Signal ((~>))
import Signal.Channel

import Routes (match, Route(..))
import App (Event(..), init, foldp, view)


main :: Eff (history:: HISTORY, channel :: CHANNEL, dom :: DOM, err :: EXCEPTION, ajax :: AJAX ) Unit
main = do
  urlSignal <- sampleURL =<< window
  let routeSignal = urlSignal ~> (PageView <<< match)

  inputChannel <- channel (PageView NotFound)
  let inputSignal = subscribe inputChannel

  app <- start
    { initialState: init
    , view
    , foldp
    , inputs: [inputSignal, routeSignal]
    }

  renderToDOM "#main" app.markup app.input

  send inputChannel (PageView Home)
  send inputChannel FetchData
