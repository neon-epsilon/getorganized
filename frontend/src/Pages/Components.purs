module Pages.Components where

import Prelude (($))
import Control.Bind (bind)
import Data.Foldable (foldMap)

import Text.Smolder.HTML (div, form, input, select, option, button)
import Text.Smolder.HTML.Attributes (className, name, type', value, required, step)
import Text.Smolder.Markup (Markup, text, (!))


container :: forall e. Markup e -> Markup e
container = div ! className "container"

box :: forall e. Markup e -> Markup e
box = div ! className "box"

smallBox :: forall e. Markup e -> Markup e
smallBox = div ! className "small-box"


customForm :: forall e. Markup e -> Markup e
customForm children =
  form $ do
    children
    input ! type' "submit" ! className "form_button" ! value "Speichern"

dateInput :: forall e. Markup e
dateInput =
  input
    ! type' "date"
    ! required "true"

numberInput :: forall e. Markup e
numberInput =
  input
    ! type' "number"
    ! step "0.01"
    ! required "true"

textInput :: forall e. Markup e
textInput =
  input
    ! type' "text"

customSelect :: forall e. Array {value :: String, text :: String} -> Markup e
customSelect options =
  select $ foldMap makeOption options
  where
    makeOption o = option ! value o.value $ text o.text
