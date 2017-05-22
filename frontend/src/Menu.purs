module Menu where

import Prelude
import Control.Bind (bind, discard)

import Text.Smolder.HTML (nav, span, input, label, ul, li, a)
import Text.Smolder.HTML.Attributes (className, id, type', for)
import Text.Smolder.Markup (text, (!), (#!))

import Pux.DOM.HTML (HTML)
import Pux.DOM.Events (onClick)



data Route = Home | Calories | HoursOfWork | Spendings | ShoppingList



menu :: String -> HTML Route
menu messageText = nav do
  input ! type' "checkbox" ! id "nav-checkbox-0"
  label ! for "nav-checkbox-0" $ do
    span ! className "nav-header" $ do
      span ! className "nav-name" $ text messageText
      span ! className "nav-icon" $ text "≡"
    ul $ do
      routeLink Home "Übersicht"
      routeLink HoursOfWork "Arbeitszeit"
      routeLink Spendings "Ausgaben"
      routeLink Calories "Kalorien"
      routeLink ShoppingList "Einkaufsliste"

routeLink :: Route -> String -> HTML Route
routeLink r s =
  li $ a #! onClick (const r) $ text s
