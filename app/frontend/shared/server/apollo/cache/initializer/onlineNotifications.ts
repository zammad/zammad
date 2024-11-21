// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import registerIncomingMerge from '#shared/server/apollo/cache/utils/registerIncomingMerge.ts'

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

export default function register(config: InMemoryCacheConfig) {
  return registerIncomingMerge(config, 'onlineNotifications', [
    'onlineNotifications',
  ])
}
