// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { relayStylePagination } from '@apollo/client/utilities'

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

export default function registerRelayStylePagination(
  config: InMemoryCacheConfig,
  queryName: string,
  fields: string[],
): InMemoryCacheConfig {
  config.typePolicies ||= {}
  config.typePolicies.Query ||= {}
  config.typePolicies.Query.fields ||= {}
  config.typePolicies.Query.fields[queryName] = relayStylePagination(fields)

  return config
}
