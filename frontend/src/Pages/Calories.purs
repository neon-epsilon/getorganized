module Pages.Calories where

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
      h2 $ text "Mahlzeit eingeben"
      customForm "calories_entries_input_form_submit" $ ul $ do
        li $ do
          label $ text "Datum:"
          dateInput
        li $ do
          label $ text "Artikel:"
          customSelect "item_id" 
            [ {value : "1", text : "Avocado (240kcal/Stück)"}
            , {value : "2", text : "Mars Eisrigel (240kcal/Stück)"}
            , {value : "3", text : "Club Mate (100kcal/Flasche)"}
            ]
        li $ do
          label $ text "Menge:"
          numberInput
      h2 $ text "Speise oder Getränk eingeben"
      customForm "calories_items_input_form_submit" $ ul $ do
        li $ do
          label $ text "Artikel:"
          textInput
        li $ do
          label $ text "Portion:"
          textInput
        li $ do
          label $ text "kcal/Portion:"
          numberInput
        li $ do
          label $ text "Kategorie:"
          customSelect "category"
            [ {value : "1", text : "Normales"}
            , {value : "2", text : "Süßigkeiten"}
            , {value : "3", text : "Getränke"}
            ]

    box $ do
      img ! src "/generated/calories/chart_7days.png"
      img ! src "/generated/calories/chart_progress.png"
