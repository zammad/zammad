// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import registerOffsetStylePagination from '#shared/server/apollo/cache/utils/registerOffsetStylePagination.ts'

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

export default function register(config: InMemoryCacheConfig) {
  return registerOffsetStylePagination(config, 'search', [
    'onlyIn',
    'search',
    'orderBy',
    'orderDirection',
  ])
}
