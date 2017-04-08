module Pages.Spendings where

import Prelude (($), bind)
import Text.Smolder.HTML (h1, h2, img, ul, li, label)
import Text.Smolder.HTML.Attributes (src)
import Text.Smolder.Markup (Markup, (!), text)

import Pages.Components


view :: forall e. Markup e
view =
  container $ do
    smallBox $ do
      h1 $ text "Eingabe"
      h2 $ text "Ausgaben eingeben"
      customForm "spendings_input_form_submit" $ ul $ do
        li $ do
          label $ text "Datum:"
          dateInput
        li $ do
          label $ text "Betrag:"
          numberInput
        li $ do
          label $ text "Kategorie:"
          customSelect "category" 
            [ {value : "1", text : "Einkaufen"}
            , {value : "2", text : "Auswärts Essen"}
            , {value : "3", text : "Freizeit"}
            , {value : "4", text : "Hobbys"}
            ]

    box $ do
      img ! src "/generated/spendings/chart_7days.png"
      img ! src "/generated/spendings/chart_progress.png"
