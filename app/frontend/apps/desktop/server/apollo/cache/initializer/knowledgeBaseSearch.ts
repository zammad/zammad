// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import registerRelayStylePagination from '#shared/server/apollo/cache/utils/registerRelayStylePagination.ts'

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

export default function register(config: InMemoryCacheConfig): InMemoryCacheConfig {
  // Unlike knowledgeBaseAnswers, `query` must be part of keyArgs here - without it Apollo would
  // merge fetchMore pages from different search terms into a single cached list.
  return registerRelayStylePagination(config, 'knowledgeBaseSearch', [
    'query',
    'categoryId',
    'locale',
  ])
}
