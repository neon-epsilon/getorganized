module Pages.Spendings where

import Pux.Html as H

import Pages.Components as C


view :: forall action. H.Html action
view =
  C.container
    [ C.smallBox
      [ C.h1 "Eingabe"
      , C.h2 "Ausgaben eingeben"
      , C.form "spendings_input_form_submit"
        [ [ C.label "Datum:"
          , C.dateInput
          ]
        , [ C.label "Betrag:"
          , C.numberInput
          , C.formHint "Format: -?\\d+(.\\d\\d?)?"           ]
        , [ C.label "Kategorie:"
          , C.select "category" 
            [ {value : "1", text : "Einkaufen"}
            , {value : "2", text : "Auswärts Essen"}
            , {value : "3", text : "Freizeit"}
            , {value : "4", text : "Hobbys"}
            ]
          ]
        ]
      ]

    , C.box
      [ C.img "/generated/spendings/chart_7days.png"
      , C.img "/generated/spendings/chart_progress.png"
      ]
    ]
