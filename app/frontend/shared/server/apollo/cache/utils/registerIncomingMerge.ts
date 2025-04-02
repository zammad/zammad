// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

export default function registerIncomingMerge(
  config: InMemoryCacheConfig,
  queryName: string,
  fields?: string[],
): InMemoryCacheConfig {
  config.typePolicies ||= {}
  config.typePolicies.Query ||= {}
  config.typePolicies.Query.fields ||= {}
  config.typePolicies.Query.fields[queryName] = {
    keyArgs: fields,
    merge(_, incoming) {
      return incoming
    },
  }

  return config
}
