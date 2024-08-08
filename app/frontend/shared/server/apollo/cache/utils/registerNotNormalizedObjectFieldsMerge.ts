// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { TypePolicy } from '@apollo/client/cache'
import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

// You can use a merge function to intelligently combine nested objects that
// are not normalized in your cache, assuming those objects are nested within the same normalized parent.
export default function registerNotNormalizedObjectFieldsMerge(
  config: InMemoryCacheConfig,
  type: string,
  fields: string[],
): InMemoryCacheConfig {
  const notNormalizedFields: Record<string, TypePolicy> = {}

  fields.forEach((field) => {
    notNormalizedFields[field] = {
      merge: (_, incoming) => incoming,
    }
  })

  config.typePolicies ||= {}
  config.typePolicies[type] ||= {}
  config.typePolicies[type].fields = notNormalizedFields

  return config
}
