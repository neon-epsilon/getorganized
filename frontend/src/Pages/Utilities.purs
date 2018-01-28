module Pages.Utilities where

import Prelude

import Data.Number (fromString)
import Data.Either (Either (..), either)
import Data.Maybe (Maybe (..))

import Control.Monad.Eff.Exception (Error)
import Control.Monad.Aff (Aff, attempt, delay)
import Control.Parallel (parallel, sequential)
import Control.Alt((<|>))

import Data.Time.Duration (Milliseconds (..))



attemptWithTimeout :: forall eff a. Aff eff a -> Number -> Aff eff (Maybe (Either Error a))
attemptWithTimeout request timeout = do
  let att = attempt $ request
  let to = delay $ Milliseconds timeout
  sequential $ parallel (Just <$> att) <|> parallel (Nothing <$ to)

