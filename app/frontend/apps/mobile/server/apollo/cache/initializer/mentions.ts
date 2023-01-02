// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'
import registerRelayStylePagination from '@shared/server/apollo/cache/utils/registerRelayStylePagination'

export default function register(config: InMemoryCacheConfig) {
  return registerRelayStylePagination(config, 'mentions', ['first'])
}
