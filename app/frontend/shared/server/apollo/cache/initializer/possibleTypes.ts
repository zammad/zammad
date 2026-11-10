// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import possibleTypesResult from '#shared/graphql/possibleTypes.api.ts'

import type { InMemoryCacheConfig } from '@apollo/client/cache'

export default function register(config: InMemoryCacheConfig): InMemoryCacheConfig {
  return {
    ...config,
    possibleTypes: {
      ...config.possibleTypes,
      ...possibleTypesResult.possibleTypes,
    },
  }
}
