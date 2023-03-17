// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'
import registerIncomingMerge from '@shared/server/apollo/cache/utils/registerIncomingMerge'

export default function register(config: InMemoryCacheConfig) {
  return registerIncomingMerge(config, 'publicLinks')
}
