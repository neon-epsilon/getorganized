module Pages.Components where

import Prelude (map)

import Pux.Html as H
import Pux.Html.Attributes as A

import Data.Array


type HtmlNode = forall action. Array (H.Html action) -> H.Html action 
type HtmlLeaf = forall action. H.Html action 

textLeaf :: 
  (forall action. Array (H.Attribute action) -> Array (H.Html action) -> H.Html action)
  -> String
  -> HtmlLeaf
textLeaf element s = element [] [H.text s]

container :: HtmlNode
container = H.div [ A.className "container"]

box :: HtmlNode
box = H.div [ A.className "box"]

smallBox :: HtmlNode
smallBox = H.div [ A.className "small-box"]


h1 :: String -> HtmlLeaf
h1 = textLeaf H.h1

h2 :: String -> HtmlLeaf
h2 = textLeaf H.h2

img :: String -> HtmlLeaf
img s = H.img [ A.src s] []


form :: forall action. String -> Array (Array (H.Html action)) -> H.Html action
form submitName children =
  H.form []
    [ H.ul []
      ( (map (H.li []) children) 
      `snoc`
        ( H.input
          [ A.name submitName
          , A.className "form_button"
          , A.type_ "submit"
          , A.value "Speichern"
          ] []
        )
      )
    ]

label :: String -> HtmlLeaf
label = textLeaf H.label

dateInput ::  HtmlLeaf
dateInput = 
  H.input
    [ A.type_ "date"
    , A.name "date"
    , A.defaultValue "2016-10-20"
    , A.placeholder "2016-10-20"
    , A.required true
    ] []

numberInput ::  HtmlLeaf
numberInput = 
  H.input
    [ A.type_ "number"
    , A.name "amount"
    , A.step "0.01"
    , A.required true
    ] []

textInput ::  HtmlLeaf
textInput = 
  H.input
    [ A.type_ "text"
    , A.name "comment"
    ] []

formHint :: String -> HtmlLeaf
formHint s = H.span [ A.className "form_hint"] [ H.text s ]

select :: String -> Array {value :: String, text :: String} -> HtmlLeaf
select name options =
  H.select [ A.name name ] (map makeOption options)
  where
    makeOption o = H.option [ A.value o.value ] [ H.text o.text ]
