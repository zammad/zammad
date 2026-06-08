// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import registerNotNormalizedObjectFieldsMerge from '../utils/registerNotNormalizedObjectFieldsMerge.ts'
import registerRelayStylePagination from '../utils/registerRelayStylePagination.ts'

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

export default function register(config: InMemoryCacheConfig) {
  registerNotNormalizedObjectFieldsMerge(config, 'User', ['ticketsCount'])

  // Use relay-style pagination for secondaryOrganizations to share cache
  // across different components regardless of the initial page size requested.
  // This allows components to request different amounts (3, 4, 5) while
  // sharing the same cached data for a given user.
  // Cache key based on field name and id only without keyword arguments
  return registerRelayStylePagination(config, 'secondaryOrganizations', false, 'User')
}
