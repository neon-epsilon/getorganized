module Pages.Home where

import Prelude (($), bind, discard)
import Text.Smolder.HTML (h1, img)
import Text.Smolder.HTML.Attributes (src)
import Text.Smolder.Markup (Markup, (!), text)

import Pages.StandardPage (State, makeImageLinkProgress)
import Pages.Components


view :: forall r e.
  { hoursOfWorkState :: State
  , spendingsState :: State
  , caloriesState :: State
  | r }
  -> Markup e
view { hoursOfWorkState, spendingsState, caloriesState } =
  container $ do
    box $ do
      h1 $ text "Ausgaben"
      makeImageLinkProgress "spendings" spendingsState
    box $ do
      h1 $ text "Kalorien"
      makeImageLinkProgress "calories" caloriesState
    box $ do
      h1 $ text "Arbeitszeit"
      makeImageLinkProgress "hoursofwork" hoursOfWorkState
