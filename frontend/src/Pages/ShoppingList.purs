module Pages.ShoppingList where

import Prelude (($), bind)
import Data.List (fromFoldable)

import Text.Smolder.HTML (h1, h2, ul, li, label)
import Text.Smolder.Markup (Markup, text)

import Pages.Components


view :: forall e. Markup e
view =
  container $ do
    box $ do
      h1 $ text "Einkaufsliste"
      h2 $ text "Einkäufe eingeben"
      customForm "Speichern" true $ ul $ do
        li $ do
          label $ text "Artikel:"
          textInput
        li $ do
          label $ text "Kategorie:"
          customSelect $ fromFoldable
            [ {value : "1", text : "Avocado (240kcal/Stück)"}
            , {value : "2", text : "Mars Eisrigel (240kcal/Stück)"}
            , {value : "3", text : "Club Mate (100kcal/Flasche)"}
            ]
      h2 $ text "Einkaufsliste"
      text "Here be dragons."