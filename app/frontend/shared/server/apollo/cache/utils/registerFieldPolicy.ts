// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { FieldPolicy } from '@apollo/client/cache'
import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

export default function registerFieldPolicy(
  config: InMemoryCacheConfig,
  type: string,
  fields: Record<string, FieldPolicy>,
): InMemoryCacheConfig {
  const defaultFields: Record<string, FieldPolicy> = {}

  Object.keys(fields).forEach((field) => {
    if (!fields[field]) return

    defaultFields[field] = fields[field]
  })

  config.typePolicies ||= {}
  config.typePolicies[type] ||= {}
  config.typePolicies[type].fields = defaultFields

  return config
}
