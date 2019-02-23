module App where

import Prelude
import Data.Maybe (Maybe (..))
import Data.Either (Either (..))

import Control.Monad.Eff.Console (CONSOLE)
import Control.Monad.Eff.Now (NOW)
import Control.Monad.Aff (Aff, delay)
import Control.Monad.Aff.Console (log, CONSOLE)
import Data.Time.Duration (Milliseconds (..))
import DOM (DOM)
import Network.HTTP.Affjax (AJAX)
import Network.HTTP.StatusCode (StatusCode(..))

import Pux (EffModel, noEffects, onlyEffects)
import Pux.DOM.HTML (HTML, mapEvent)
import Text.Smolder.HTML (h1)
import Text.Smolder.Markup (text)

import App.Component
import Menu (Route (..), menu)
import Pages.Home as Home
import Pages.StandardPage as StandardPage
import Pages.ShoppingList as ShoppingList

import Utilities


hoursOfWorkResource = "hoursofwork"
spendingsResource = "spendings"
caloriesResource = "calories"



data Event =
  Init |
  InitComponents |
  NavigateTo Route |
  FlashMessage String |
  UnFlashMessage Int |
  HoursOfWorkEvent StandardPage.Event |
  SpendingsEvent StandardPage.Event |
  CaloriesEvent StandardPage.Event |
  ShoppingListEvent ShoppingList.Event


type State =
  { currentRoute :: Route
  , message :: Maybe Message
  , hoursOfWorkState :: StandardPage.State
  , spendingsState :: StandardPage.State
  , caloriesState :: StandardPage.State
  , shoppingListState :: ShoppingList.State }

newtype Message = Message
  { messageText :: String
  , messageId :: Int }
  -- messageId is needed to correctly stop showing messages after a given time.

init :: State
init =
  { currentRoute : Home
  , message : Nothing
  , hoursOfWorkState : StandardPage.init
  , spendingsState : StandardPage.init
  , caloriesState : StandardPage.init
  , shoppingListState : ShoppingList.init }


-- The "forall eff" is important. Without it the effects available to
-- the main monad get restricted which leads to a compiler error.
foldp :: forall eff. Event -> State
  -> EffModel State Event (ajax :: AJAX, console :: CONSOLE, dom :: DOM, now :: NOW | eff)
foldp (NavigateTo route) state = noEffects $ state { currentRoute = route }
foldp Init state =
  onlyEffects state [checkIfAuthenticated]
foldp InitComponents state =
  { state: state
  , effects:
    [ pure $ Just $ HoursOfWorkEvent StandardPage.Init
    , pure $ Just $ SpendingsEvent StandardPage.Init
    , pure $ Just $ CaloriesEvent StandardPage.Init
    , pure $ Just $ ShoppingListEvent ShoppingList.Init ]
  }
foldp (FlashMessage s) state@{message} =
  { state: state { message = Just (Message {messageText : s, messageId: id}) }
  , effects: [ timeout ] }
  where
    id = case message of
      Nothing -> 0
      Just (Message {messageId}) -> messageId + 1
    timeout = do
      delay $ Milliseconds 5000.0
      pure $ Just $ UnFlashMessage id
foldp (UnFlashMessage id) state@{message} =
  noEffects $ state { message = newMessage }
  where
    newMessage = case message of
      Just (Message {messageId}) -> if messageId == id
        then Nothing
        else message
      _ -> message
foldp (HoursOfWorkEvent hoursOfWorkEvent) state@{hoursOfWorkState} =
  { state: state {hoursOfWorkState = hoursOfWorkEffModel.state }
  , effects: effects }
  where
    hoursOfWorkEffModel = (StandardPage.makeFoldp hoursOfWorkResource) hoursOfWorkEvent hoursOfWorkState
    hoursOfWorkEffects = map (map HoursOfWorkEvent) <$> hoursOfWorkEffModel.effects
    effects = case getAppEvent hoursOfWorkEvent of
      NoOp -> hoursOfWorkEffects
      UserMessage s -> [pure $ Just $ FlashMessage s] <> hoursOfWorkEffects
foldp (SpendingsEvent spendingsEvent) state@{spendingsState} =
  { state: state {spendingsState = spendingsEffModel.state }
  , effects: effects }
  where
    spendingsEffModel = (StandardPage.makeFoldp spendingsResource) spendingsEvent spendingsState
    spendingsEffects = map (map SpendingsEvent) <$> spendingsEffModel.effects
    effects = case getAppEvent spendingsEvent of
      NoOp -> spendingsEffects
      UserMessage s -> [pure $ Just $ FlashMessage s] <> spendingsEffects
foldp (CaloriesEvent caloriesEvent) state@{caloriesState} =
  { state: state {caloriesState = caloriesEffModel.state }
  , effects: effects }
  where
    caloriesEffModel = (StandardPage.makeFoldp caloriesResource) caloriesEvent caloriesState
    caloriesEffects = map (map CaloriesEvent) <$> caloriesEffModel.effects
    effects = case getAppEvent caloriesEvent of
      NoOp -> caloriesEffects
      UserMessage s -> [pure $ Just $ FlashMessage s] <> caloriesEffects
foldp (ShoppingListEvent shoppingListEvent) state@{shoppingListState} =
  { state: state {shoppingListState = shoppingListEffModel.state }
  , effects: effects }
  where
    shoppingListEffModel = ShoppingList.foldp shoppingListEvent shoppingListState
    shoppingListEffects = map (map ShoppingListEvent) <$> shoppingListEffModel.effects
    effects = case getAppEvent shoppingListEvent of
      NoOp -> shoppingListEffects
      UserMessage s -> [pure $ Just $ FlashMessage s] <> shoppingListEffects

checkIfAuthenticated :: forall eff. Aff (ajax :: AJAX, console :: CONSOLE | eff) (Maybe Event)
checkIfAuthenticated = do
  maybeRes <- attemptWithTimeout 10000.0 (getWithoutCaching "/index.html")
  case maybeRes of
    Just (Right res) | res.status == (StatusCode 200) -> do
      pure $ Just $ InitComponents
    -- if status is 401, wait ten seconds and try again
    Just (Right res) | res.status == (StatusCode 401) -> do
      delay $ Milliseconds 10000.0
      checkIfAuthenticated
    -- If status is neither 200 nor 401, we expect an object of the form {error: String}
    Just (Right res) -> do
      log $ "Error: Expected status 200, received " <> (\(StatusCode n) -> show n) res.status <> " while checking if authenticated."
      log $ "Response from server:"
      log res.response
      delay $ Milliseconds 1000.0
      checkIfAuthenticated
    Just (Left err) -> do
      log $ show err
      delay $ Milliseconds 1000.0
      checkIfAuthenticated
    Nothing -> do
      log $ "Error: Request timed out while checking if authenticated."
      checkIfAuthenticated




view :: State -> HTML Event
view s = do
  let message = case s.message of
                      Nothing -> "GetOrganized"
                      Just (Message { messageText }) -> messageText
  mapEvent NavigateTo $ menu message
  viewContainer s

viewContainer :: State -> HTML Event
viewContainer state@{ currentRoute: Home } =
  Home.view state
viewContainer { currentRoute: HoursOfWork, hoursOfWorkState } =
  mapEvent HoursOfWorkEvent $ (StandardPage.makeView hoursOfWorkResource) hoursOfWorkState
viewContainer { currentRoute: Spendings, spendingsState } =
  mapEvent SpendingsEvent $ (StandardPage.makeView spendingsResource) spendingsState
viewContainer { currentRoute: Calories, caloriesState } =
  mapEvent CaloriesEvent $ (StandardPage.makeView caloriesResource) caloriesState
viewContainer { currentRoute: ShoppingList, shoppingListState } =
  mapEvent ShoppingListEvent $ ShoppingList.view shoppingListState
