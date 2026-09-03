// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import registerRelayStylePagination from '#shared/server/apollo/cache/utils/registerRelayStylePagination.ts'

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

export default function register(config: InMemoryCacheConfig): InMemoryCacheConfig {
  // `sortingMode` belongs in the key for the same reason `query` does on knowledgeBaseSearch: a
  // listing asked for in another order is another connection, and without it Apollo would both
  // merge pages of two different orders into one cached list and answer the sorting bar's preview
  // from the cache instead of fetching it.
  return registerRelayStylePagination(config, 'knowledgeBaseAnswers', [
    'categoryId',
    'locale',
    'sortingMode',
  ])
}
