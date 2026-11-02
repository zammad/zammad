// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import registerIncomingQueryMerge from '#shared/server/apollo/cache/utils/registerIncomingQueryMerge.ts'

import type { InMemoryCacheConfig } from '@apollo/client/cache'

export default function register(config: InMemoryCacheConfig): InMemoryCacheConfig {
  // Autocomplete responses are complete lists; matches removed by a refresh must leave the cache.
  const fields = [
    'autocompleteSearchAgent',
    'autocompleteSearchGeneric',
    'autocompleteSearchIdoitObjectTypes',
    'autocompleteSearchKnowledgeBaseAnswer',
    'autocompleteSearchKnowledgeBaseCategoryIcon',
    'autocompleteSearchObjectAttributeExternalDataSource',
    'autocompleteSearchOrganization',
    'autocompleteSearchRecipient',
    'autocompleteSearchTag',
    'autocompleteSearchTicket',
    'autocompleteSearchUser',
  ]

  fields.forEach((field) => registerIncomingQueryMerge(config, field))

  return config
}
