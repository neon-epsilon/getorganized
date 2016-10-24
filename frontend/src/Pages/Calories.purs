module Pages.Calories where

import Pux.Html as H

import Pages.Components as C


view :: forall action. H.Html action
view =
  C.container
    [ C.smallBox
      [ C.h1 "Eingabe"
      , C.h2 "Mahlzeit eingeben"
      , C.form "calories_entries_input_form_submit"
        [ [ C.label "Datum:"
          , C.dateInput
          ]
        , [ C.label "Artikel:"
          , C.select "category" 
            [ {value : "1", text : "Avocado (240kcal/Stück)"}
            , {value : "2", text : "Mars Eisrigel (240kcal/Stück)"}
            , {value : "3", text : "Club Mate (100kcal/Flasche)"}
            ]
          ]
        , [ C.label "Menge:"
          , C.numberInput
          , C.formHint "Format: -?\\d+(.\\d\\d?)?"           ]
        ]
      , C.h2 "Speise eingeben"
      , C.form "calories_items_input_form_submit"
        [ [ C.label "Artikel:"
          , C.textInput
          ]
        , [ C.label "Portion:"
          , C.textInput
          ]
        , [ C.label "kcal/Einheit:"
          , C.numberInput
          , C.formHint "Format: -?\\d+(.\\d\\d?)?"           ]
        , [ C.label "Kategorie:"
          , C.select "category" 
            [ {value : "1", text : "Normales"}
            , {value : "2", text : "Süßigkeiten"}
            , {value : "3", text : "Getränke"}
            ]
          ]
        ]
      ]

    , C.box
      [ C.img "/generated/calories/chart_7days.png"
      , C.img "/generated/calories/chart_progress.png"
      ]
    ]
