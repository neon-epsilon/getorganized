module App.Component where

data AppEvent = NoOp
  | FatalError String
  | Error String

class ComponentEvent e where
  getAppEvent :: e -> AppEvent
