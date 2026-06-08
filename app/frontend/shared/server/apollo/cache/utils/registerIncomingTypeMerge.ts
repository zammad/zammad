// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FieldPolicy } from '@apollo/client/cache'
import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

/**
 * Whenever you are configuring the behavior for a nested fields on specific type
 * Merging nested objects
 * Fixing non-normalizes structures
 */
export default function registerIncomingQueryMerge(
  config: InMemoryCacheConfig,
  type: string,
  fields: string[],
): InMemoryCacheConfig {
  config.typePolicies ||= {}
  config.typePolicies[type] ||= {}
  config.typePolicies[type].fields ||= {}

  const defaultFields: Record<string, FieldPolicy> = {}

  fields.forEach((field) => {
    defaultFields[field] = {
      merge: (_, incoming) => incoming,
    }
  })

  config.typePolicies[type].fields = {
    ...config.typePolicies[type].fields,
    ...defaultFields,
  }

  return config
}
