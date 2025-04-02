// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import registerNotNormalizedObjectFieldsMerge from '#shared/server/apollo/cache/utils/registerNotNormalizedObjectFieldsMerge.ts'

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

export default function register(config: InMemoryCacheConfig) {
  return registerNotNormalizedObjectFieldsMerge(config, 'Ticket', ['policy'])
}
