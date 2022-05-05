// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'
import { relayStylePagination } from '@apollo/client/utilities'

export default function registerRelayStylePagination(
  config: InMemoryCacheConfig,
  queryName: string,
  fields: string[],
): InMemoryCacheConfig {
  /* eslint-disable no-param-reassign */
  config.typePolicies ||= {}
  config.typePolicies.Query ||= {}
  config.typePolicies.Query.fields ||= {}
  config.typePolicies.Query.fields[queryName] = relayStylePagination(fields)

  return config
}
