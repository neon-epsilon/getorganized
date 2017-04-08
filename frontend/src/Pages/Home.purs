module Pages.Home where

import Prelude (($), bind)
import Text.Smolder.HTML (h1, img)
import Text.Smolder.HTML.Attributes (src)
import Text.Smolder.Markup (Markup, (!), text)

import Pages.Components


view :: forall e. Markup e
view =
  container $ do
    box $ do
      h1 $ text "Ausgaben"
      img ! src "/generated/spendings/chart_progress.png"
    box $ do
      h1 $ text "Kalorien"
      img ! src "/generated/calories/chart_progress.png"
    box $ do
     h1 $ text "Arbeitszeit"
     img ! src "/generated/hoursofwork/chart_progress.png"
