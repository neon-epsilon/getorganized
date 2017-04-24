module Menu where

import Prelude (($))
import Control.Bind (bind)

import Text.Smolder.HTML (nav, span, input, label, ul, li, a)
import Text.Smolder.HTML.Attributes (className, id, type', for, href)
import Text.Smolder.Markup (Markup, text, (!))



menu :: forall e. Markup e
menu = nav do
  input ! type' "checkbox" ! id "nav-checkbox-0"
  label ! for "nav-checkbox-0" $ do
    span ! className "nav-name" $ text "GetOrganized"
    span ! className "nav-icon" $ text "≡"
  ul $ do
    li $ a ! href "/" ! className "route-link" $ text "Übersicht"
    li $ a ! href "/hoursofwork" ! className "route-link" $ text "Arbeitszeit"
    li $ a ! href "/spendings" ! className "route-link" $ text "Ausgaben"
    li $ a ! href "/calories" ! className "route-link" $ text "Kalorien"
    li $ a ! href "/shoppinglist" ! className "route-link" $ text "Einkaufsliste"
