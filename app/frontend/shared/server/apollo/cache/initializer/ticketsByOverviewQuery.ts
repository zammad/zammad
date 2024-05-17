// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import registerRelayStylePagination from '#shared/server/apollo/cache/utils/registerRelayStylePagination.ts'

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

export default function register(
  config: InMemoryCacheConfig,
): InMemoryCacheConfig {
  return registerRelayStylePagination(config, 'ticketsByOverview', [
    'overviewId',
    'orderBy',
    'orderDirection',
  ])
}
