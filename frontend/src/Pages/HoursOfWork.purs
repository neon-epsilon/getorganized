module Pages.HoursOfWork where


import Data.Either (Either(Left, Right), either)

import Pux.Html as H

import Pages.Components as C


data Action = RequestCategories | ReceiveCategories (Either String (Array String))


data DataState = Fetching | HasData

type Category =
  { category :: String
  , priority :: Int
  }

type State =
  { dataState :: DataState
  , categories :: Array Category
  }

view :: forall action. H.Html action
view =
  C.container
    [ C.smallBox
      [ C.h1 "Eingabe"
      , C.h2 "Arbeitszeit eingeben"
      , C.form "hoursofwork_input_form_submit"
        [ [ C.label "Datum:"
          , C.dateInput
          ]
        , [ C.label "Stunden:"
          , C.numberInput
          , C.formHint "Format: \\d+(.\\d\\d?)?"           ]
        , [ C.label "Kategorie:"
          , C.select "category"
            [ {value : "1", text : "Uni"}
            , {value : "2", text : "Nebenjob"}
            ]
          ]
        ]
      ]

    , C.box
      [ C.img "/generated/hoursofwork/chart_7days.png"
      , C.img "/generated/hoursofwork/chart_progress.png"
      ]
    ]
