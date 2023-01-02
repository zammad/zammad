// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'
import { relayStylePagination } from '@apollo/client/utilities'

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
