module Pages.Home where

import Pux.Html as H

import Pages.Components as C


view :: forall action. H.Html action
view =
  C.container
    [ C.box
      [ C.h1 "Ausgaben"
      , C.img "/generated/spendings/chart_progress.png"
      ]
    , C.box
      [ C.h1 "Kalorien"
      , C.img "/generated/calories/chart_progress.png"
      ]
    , C.box
      [ C.h1 "Arbeitszeit"
      , C.img "/generated/hoursofwork/chart_progress.png"
      ]
    ]
