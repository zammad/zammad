// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

// if a new array is returned and length differs, cache doesn't like it,
// and we need to tell apollo that it needs to just replace current state altogether
// this should be used only, if you are not using pagination
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
