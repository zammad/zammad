// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ConfigList } from '#shared/types/store.ts'

import type { RouteResponse } from './commands.mts'

declare module 'vitest/browser' {
  interface BrowserCommands {
    moveMouseAway: () => Promise<void>
    routeRequest: (url: string, response: RouteResponse) => Promise<void>
    unrouteRequest: (url: string) => Promise<void>
  }
}

export interface MountOptions {
  // Applied before the component is set up, which may read them only once.
  config?: Partial<ConfigList>
  permissions?: string[]
  // The signed-in user, for a component that tells their records from others'; needs `permissions`.
  userId?: string
}
