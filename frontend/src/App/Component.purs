module App.Component where

data AppEvent = NoOp
  | UserMessage String

class ComponentEvent e where
  getAppEvent :: e -> AppEvent
