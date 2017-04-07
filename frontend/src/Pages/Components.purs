module Pages.Components where

import Prelude (($))
import Control.Bind (bind)
import Data.Foldable (foldMap)

import Text.Smolder.HTML (div, span, form, ul, input, select, option)
import Text.Smolder.HTML.Attributes (className, name, type', value, placeholder, required, step)
import Text.Smolder.Markup (Attribute, Markup, attribute, text, (!))

defaultValue :: String -> Attribute
defaultValue = attribute "defaultValue"


container :: forall e. Markup e -> Markup e
container = div ! className "container"

box :: forall e. Markup e -> Markup e
box = div ! className "box"

smallBox :: forall e. Markup e -> Markup e
smallBox = div ! className "small-box"


customForm :: forall e. String -> Markup e -> Markup e
customForm submitName children =
  form $ ul $ do
      children
      input
        ! name submitName
        ! className "form_button"
        ! type' "submit"
        ! value "Speichern"

dateInput :: forall e. Markup e
dateInput = 
  input
    ! type' "date"
    ! name "date"
    ! defaultValue "2016-10-20"
    ! placeholder "2016-10-20"
    ! required "true"

numberInput :: forall e. Markup e
numberInput = 
  input
    ! type' "number"
    ! name "amount"
    ! step "0.01"
    ! required "true"

textInput :: forall e. Markup e
textInput = 
  input
    ! type' "text"
    ! name "comment"

formHint :: forall e. String -> Markup e
formHint s = span ! className "form_hint" $ text s

customSelect :: forall e. String -> Array {value :: String, text :: String} -> Markup e
customSelect selectName options =
  select ! name selectName $ foldMap makeOption options
  where
    makeOption o = option ! value o.value $ text o.text
