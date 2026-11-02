// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import registerFieldPolicy from '#shared/server/apollo/cache/utils/registerFieldPolicy.ts'

import type { InMemoryCacheConfig } from '@apollo/client/cache'

export default function register(config: InMemoryCacheConfig) {
  return registerFieldPolicy(config, 'Ticket', {
    policy: { merge: true },
    // The server always sends the complete list and its entries have no identity,
    // so the incoming list replaces the cached one.
    timeUnitsPerType: { merge: false },
  })
}
