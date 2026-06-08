// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import registerIncomingQueryMerge from '#shared/server/apollo/cache/utils/registerIncomingQueryMerge.ts'

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

export default function register(config: InMemoryCacheConfig) {
  return registerIncomingQueryMerge(config, 'userCurrentDeviceList')
}
