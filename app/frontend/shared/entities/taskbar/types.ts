// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { EnumTaskbarApp, TicketLiveUser } from '#shared/graphql/types.ts'

export interface TaskbarLiveUserApp {
  name: EnumTaskbarApp
  editing: boolean
  lastInteraction: string
}

// The live user list entry a subscription returns, named after no entity: the ticket and the
//   knowledge base answer subscription return the same shape under two GraphQL type names, so a
//   generated type of either would only fit its own caller (`__typename` is a literal in them).
//
// `user` stays the schema-wide `User`, which is what the popovers rendering the list take - the
//   narrower selection a fragment returns is cast into it at each caller, as it already was.
export interface TaskbarLiveUser {
  user: TicketLiveUser['user']
  apps: TaskbarLiveUserApp[]
}

// One entry of a live user list, flattened to the app the user was last active in.
export interface TaskbarLiveAppUser {
  user: TaskbarLiveUser['user']
  editing: boolean
  lastInteraction?: string
  app: EnumTaskbarApp
  isIdle?: boolean
}
