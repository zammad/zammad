// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import registerNotNormalizedObjectFieldsMerge from '#shared/server/apollo/cache/utils/registerNotNormalizedObjectFieldsMerge.ts'

import registerRelayStylePagination from '../utils/registerRelayStylePagination.ts'

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

export default function register(config: InMemoryCacheConfig) {
  registerNotNormalizedObjectFieldsMerge(config, 'Organization', ['allMembers', 'ticketsCount'])

  // Different page size requests won't override the cache it will
  // receive whatever entries are already cached. However, fetching new data can
  // overwrite the cache, which may affect other components relying on that data.
  return registerRelayStylePagination(config, 'allMembers', false, 'Organization')
}
