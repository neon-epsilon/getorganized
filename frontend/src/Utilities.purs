module Utilities where

import Prelude

import Data.Number (fromString)
import Data.Either (Either (..), either)
import Data.Maybe (Maybe (..))

import Control.Monad.Eff.Exception (Error)
import Control.Monad.Aff (Aff, attempt, delay)
import Control.Parallel (parallel, sequential)
import Control.Alt((<|>))

import Data.Time.Duration (Milliseconds (..))

import Network.HTTP.Affjax (URL, Affjax, affjax, defaultRequest)
import Network.HTTP.Affjax.Response (class Respondable)
import Network.HTTP.RequestHeader (RequestHeader(..))



attemptWithTimeout :: forall eff a. Number -> Aff eff a -> Aff eff (Maybe (Either Error a))
attemptWithTimeout timeout request = do
  let att = attempt $ request
  let to = delay $ Milliseconds timeout
  sequential $ parallel (Just <$> att) <|> parallel (Nothing <$ to)


getWithoutCaching :: forall e a. Respondable a => URL -> Affjax e a
getWithoutCaching u = affjax $
  defaultRequest { url = u , headers =
    [ RequestHeader "Cache-Control" "no-cache, no-store, must-revalidate"
    , RequestHeader "Pragma" "no-cache"
    , RequestHeader "Expires" "0"
    ] }
