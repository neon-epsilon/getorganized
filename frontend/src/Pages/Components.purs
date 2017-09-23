module Pages.Components where

import Prelude (($), otherwise)
import Control.Bind (bind, discard)
import Data.List (List)
import Data.Foldable (for_)

import Text.Smolder.HTML (div, form, input, select, option, button)
import Text.Smolder.HTML.Attributes (className, type', value, required, step, disabled)
import Text.Smolder.Markup (Markup, text, (!))


container :: forall e. Markup e -> Markup e
container = div ! className "container"

box :: forall e. Markup e -> Markup e
box = div ! className "box"

smallBox :: forall e. Markup e -> Markup e
smallBox = div ! className "small-box"


customForm :: forall e. String -> Boolean -> Markup e -> Markup e
customForm buttonText isActive children =
  form $ do
    children
    -- It is important to button and not input: With input, (p)react may create errors.
    formButton
  where
    formButton | isActive =
                  button ! type' "submit" ! className "form_button" $ text buttonText
               | otherwise =
                  button ! type' "submit" ! className "form_button" ! disabled "true" $ text buttonText

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

customSelect :: forall e. List {value :: String, text :: String} -> Markup e
customSelect options =
  select $ for_ options makeOption
  where
    makeOption o = option ! value o.value $ text o.text
