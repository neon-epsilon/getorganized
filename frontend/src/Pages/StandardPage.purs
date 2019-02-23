module Pages.StandardPage where

import Prelude

import Data.Maybe (Maybe(..), maybe)
import Data.Either (Either(..), either)
import Data.Number (fromString)

import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Aff (Aff, attempt, delay)

import Control.Monad.Aff.Console (CONSOLE, log)
import Network.HTTP.Affjax (AJAX)
import Network.HTTP.StatusCode (StatusCode(..))
import DOM (DOM)

import Control.Monad.Eff.Now (NOW, now)
import Data.DateTime.Instant (Instant, unInstant, instant)
import Data.Time.Duration(Milliseconds(..))

import Pux (EffModel, noEffects, onlyEffects)
import Pux.DOM.HTML (HTML, mapEvent)
import Text.Smolder.Markup (Markup, (!), text)
import Text.Smolder.HTML (img)
import Text.Smolder.HTML.Attributes (src, className)

import Pages.Components
import App.Component as AppComp
import Pages.Components.InputForm as IF
import Pages.Components.DeleteForm as DF

import Utilities


data Event =
    Init
  | Picture PictureEvent
  | InputFormEvent IF.Event
  | DeleteFormEvent DF.Event

data PictureEvent =
    CheckIfReady {timestamp :: Instant, retries :: Int}
  | UpdatePicture
  | UpdateTimestamp String

instance appComponentEvent :: AppComp.ComponentEvent Event where
  getAppEvent (InputFormEvent ev) = AppComp.getAppEvent ev
  getAppEvent (DeleteFormEvent ev) = AppComp.getAppEvent ev
  getAppEvent _ = AppComp.NoOp



type State =
  { pictureState :: {timestamp :: String, waitingForUpdate :: Maybe Instant}
  , inputFormState :: IF.State
  , deleteFormState :: DF.State
  }


init :: State
init =
  { pictureState : {timestamp: "0", waitingForUpdate: Nothing}
  , inputFormState : IF.init
  , deleteFormState : DF.init
  }


makeView :: String -> State -> HTML Event
makeView resourceName = view
  where
  view state@{ inputFormState, deleteFormState, pictureState } =
    container $ do
      smallBox $ do
        mapEvent InputFormEvent $ IF.view inputFormState
        mapEvent DeleteFormEvent $ DF.view deleteFormState
      box $ do
        makeImageLink7Days resourceName state
        makeImageLinkProgress resourceName state

makeImageLink7Days :: forall e. String -> State -> Markup e
makeImageLink7Days resourceName {pictureState} =
  styledImage ! src ("/generated/" <> resourceName <> "/chart_7days.png?" <> pictureState.timestamp)
  where
  styledImage = case pictureState.waitingForUpdate of
    Nothing -> img
    _ -> img ! className "loading"
makeImageLinkProgress :: forall e. String -> State -> Markup e
makeImageLinkProgress resourceName {pictureState} =
  styledImage ! src ("/generated/" <> resourceName <> "/chart_progress.png?" <> pictureState.timestamp)
  where
  styledImage = case pictureState.waitingForUpdate of
    Nothing -> img
    _ -> img ! className "loading"



makeFoldp :: forall eff. String -> Event -> State
  -> EffModel State Event (ajax :: AJAX, console :: CONSOLE, dom :: DOM, now :: NOW | eff)
makeFoldp resourceName = foldp
  where
  foldp Init state =
    { state : state
    , effects :
      [ pure $ Just $ Picture UpdatePicture
      , pure $ Just $ InputFormEvent IF.Init
      , pure $ Just $ DeleteFormEvent DF.Init ] }

  foldp (Picture UpdatePicture) state =
    onlyEffects state [ do
      n <- (liftEff now)
      pure $ Just $ Picture $ UpdateTimestamp $ (\(Milliseconds t) -> show t) (unInstant n)
      ]
  foldp (Picture (UpdateTimestamp t)) state =
    noEffects $ state { pictureState = {timestamp: t, waitingForUpdate: Nothing} }
  foldp (Picture (CheckIfReady {timestamp, retries})) state@{pictureState} =
    case pictureState.waitingForUpdate of
      -- If l > timestamp, a newer CheckIfReady must have been triggered in the meantiime.
      Just l | l > timestamp -> noEffects state
      _ ->
        { state: state{ pictureState{waitingForUpdate = Just timestamp} }
        , effects: [ checkTimeStamp resourceName timestamp retries ] }

  foldp (InputFormEvent ev) state@{inputFormState} =
    { state: state { inputFormState = inputFormEffModel.state }
    , effects: effects }
    where
      inputFormEffModel = (IF.makeFoldp resourceName) ev inputFormState
      inputFormEffects = map (map InputFormEvent) <$> inputFormEffModel.effects
      deleteFormEvent = map DeleteFormEvent $ IF.deleteFormEvent ev
      pictureEvent = case ev of
        (IF.UpdatePicture timestamp) -> Just $ Picture $ CheckIfReady {timestamp, retries:0}
        _ -> Nothing
      effects =
        inputFormEffects <>
        [ pure deleteFormEvent
        , pure pictureEvent ]

  foldp (DeleteFormEvent ev) state@{deleteFormState} =
    { state: state { deleteFormState = deleteFormEffModel.state }
    , effects: effects }
    where
      deleteFormEffModel = (DF.makeFoldp resourceName) ev deleteFormState
      deleteFormEffects = map (map DeleteFormEvent) <$> deleteFormEffModel.effects
      pictureEvent = case ev of
        (DF.UpdatePicture timestamp) -> Just $ Picture $ CheckIfReady {timestamp, retries:0}
        _ -> Nothing
      effects = deleteFormEffects <> [ pure pictureEvent ]

checkTimeStamp :: forall eff. String -> Instant -> Int -> Aff (ajax :: AJAX, console :: CONSOLE | eff) (Maybe Event)
checkTimeStamp resourceName stateTimestamp retries = do
  maybeRes <- attemptWithTimeout 10000.0 (getWithoutCaching $ "/generated/" <> resourceName <> "/timestamp")
  case maybeRes of
    Just (Right res) | res.status == (StatusCode 200) -> do
      let ts = fromString res.response
      maybe
        -- Just wait a few seconds and reload the picture with the most recent timestamp if we cannot read the generated timestamp.
        ( do
          log $ "Error: Timestamp is not of type Number."
          reloadAnywayAfterDelay
        )
        -- See, if received timestamp is greater or equal than t.
        -- If so, issue reload. Otherwise wait a second and try again.
        -- If number of retries is too high, just reload.
        ( \x ->
          if (Milliseconds x) >= (unInstant stateTimestamp) then
            pure $ Just $ Picture $ UpdatePicture
          else if retries < 30 then do
            delay $ Milliseconds 1000.0
            pure $ Just $ Picture $ CheckIfReady { timestamp: stateTimestamp, retries: retries + 1 }
          else do
            log $ "Error: Timestamp does not update on server."
            reloadAnywayAfterDelay
        )
        ts
    -- | If status is not 200, we expect an object of the form {error: String}
    Just (Right res) -> do
      log $ "Error: Expected status 200, received " <> (\(StatusCode n) -> show n) res.status <> " while GETting timestamp."
      log $ "Response from server:"
      log res.response
      reloadAnywayAfterDelay
    Just (Left err) -> do
      log $ show err
      reloadAnywayAfterDelay
    Nothing -> do
      log $ "Error: Request timed out while GETting timestamp."
      reloadAnywayAfterDelay -- maybe it is smarter to try to GET the timestamp again?
  where
    reloadAnywayAfterDelay = do
      delay $ Milliseconds 5000.0
      pure $ Just $ Picture $ UpdatePicture
