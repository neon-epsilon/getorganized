module Pages.ShoppingList where

import Pux.Html as H

import Pages.Components as C


view :: forall action. H.Html action
view =
  C.container
    [ C.box
      [ C.h1 "Einkaufsliste"
      , C.h2 "Einkäufe eingeben"
      , C.form "shoppinglist_input_form_submit"
        [ [ C.label "Artikel:"
          , C.textInput
          ]
        , [ C.label "Kategorie:"
          , C.select "category" 
            [ {value : "1", text : "Avocado (240kcal/Stück)"}
            , {value : "2", text : "Mars Eisrigel (240kcal/Stück)"}
            , {value : "3", text : "Club Mate (100kcal/Flasche)"}
            ]
          ]
        ]
      , C.h2 "Einkaufsliste"
      , H.text "Here be dragons."
      ]
    ]