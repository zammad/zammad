// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

/**
 * Whenever we are trying to merge a root query field
 * Directly under the Query in the schema,
 * Check root in apollo cache tools if unsure
 * keyArgs arg the variables passed to the query
 * @example query macros($groupIds: [ID!]!) ...
 * queryname: macros
 * keyArgs: groupIds
 * @see https://www.apollographql.com/docs/react/caching/cache-field-behavior/#merging-non-normalized-data
 */
export default function registerIncomingQueryMerge(
  config: InMemoryCacheConfig,
  queryName: string,
  keyArgs?: string[],
): InMemoryCacheConfig {
  config.typePolicies ||= {}
  config.typePolicies.Query ||= {}
  config.typePolicies.Query.fields ||= {}
  config.typePolicies.Query.fields[queryName] = {
    keyArgs: keyArgs,
    merge(_, incoming) {
      return incoming
    },
  }

  return config
}
