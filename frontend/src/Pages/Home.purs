module Pages.Home where

import Pux.Html as H

import Pages.Components as C


view :: forall action. H.Html action
view =
  C.container
    [ C.smallBox
      [ C.h1 "Eingabemaske"
      , C.h2 "Irgendwas eingeben"
      , C.form "spendings_input_form_submit"
        [ [ C.label "Datum:"
          , C.dateInput
          ]
        , [ C.label "Betrag:"
          , C.numberInput
          , C.formHint "Format: -?\\d+(.\\d+)?"           ]
        , [ C.label "Kategorie:"
          , C.select "category" 
            [ {value : "category1", text : "Kategorie 1"}
            , {value : "category2", text : "Kategorie 2"}
            ]
          , C.formHint "Format: -?\\d+(.\\d+)?" 
          ]
        , [ C.label "(Kommentar):"
          , C.textInput
          ]
        ]
      ]

    , C.box
      [ C.img "/generated/spendings/chart_7days.png"
      , C.img "/generated/spendings/chart_progress.png"
      ]
    ]
