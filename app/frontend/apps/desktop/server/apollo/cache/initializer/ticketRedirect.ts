// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import registerRedirect from '#shared/server/apollo/cache/utils/registerRedirect.ts'

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

export default function register(config: InMemoryCacheConfig) {
  return registerRedirect(config, 'ticket', 'Ticket')
}
