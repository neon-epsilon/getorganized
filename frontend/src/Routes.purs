module Routes where

import Control.Alt ((<|>))
import Control.Apply ((<*))
import Data.Functor ((<$))
import Data.Maybe (fromMaybe)
import Prelude (($), class Show)
import Pux.Router (router, lit, end)

data Route = Home | Calories | HoursOfWork | Spendings | ShoppingList | NotFound

instance showRoute :: Show Route where
  show Home = "Home"
  show Calories = "Calories"
  show HoursOfWork = "HoursOfWork"
  show Spendings = "Spendings"
  show ShoppingList = "ShoppingList"
  show NotFound = "NotFound"

match :: String -> Route
match url = fromMaybe NotFound $ router url $
  Home <$ end
  <|>
  Calories <$ (lit "calories") <* end
  <|>
  HoursOfWork <$ (lit "hoursofwork") <* end
  <|>
  Spendings <$ (lit "spendings") <* end
  <|>
  ShoppingList <$ (lit "shoppinglist") <* end
