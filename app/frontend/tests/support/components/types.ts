// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

type DependencyProvide = [symbol | string, any]

export type DependencyProvideApi = DependencyProvide[]

export interface SessionHistoryWindow extends Window {
  // jsdom internal, not part of the DOM API.
  _sessionHistory?: { clearHistoryTraversalTasks(): void }
}
