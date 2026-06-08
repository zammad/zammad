// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { relayStylePagination } from '@apollo/client/utilities'

import type { FieldPolicy } from '@apollo/client/cache/inmemory/policies'
import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

export default function registerRelayStylePagination(
  config: InMemoryCacheConfig,
  fieldName: string,
  keyArgs?: FieldPolicy['keyArgs'],
  typeName: string = 'Query',
): InMemoryCacheConfig {
  config.typePolicies ||= {}
  config.typePolicies[typeName] ||= {}
  config.typePolicies[typeName].fields ||= {}
  config.typePolicies[typeName].fields[fieldName] = relayStylePagination(keyArgs)

  return config
}
