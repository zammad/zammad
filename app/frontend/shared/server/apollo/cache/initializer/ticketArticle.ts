// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import registerIncomingTypeMerge from '../utils/registerIncomingTypeMerge.ts'

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

export default function register(config: InMemoryCacheConfig): InMemoryCacheConfig {
  return registerIncomingTypeMerge(config, 'TicketArticle', ['highlightedTexts'])
}
