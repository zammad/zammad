// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { EventActionModule } from '../types.ts'

const eventActionModules = import.meta.glob<EventActionModule>(
  ['./*.ts', '!./index.ts'],
  {
    eager: true,
    import: 'default',
  },
)

// Put all event actions from the glob output into an hash
const eventActions = Object.entries(eventActionModules).reduce(
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  (lookup: Record<string, EventActionModule>, [_, module]) => {
    lookup[module.name] = module
    return lookup
  },
  {} as Record<string, EventActionModule>,
)

export const eventActionsLookup = eventActions
