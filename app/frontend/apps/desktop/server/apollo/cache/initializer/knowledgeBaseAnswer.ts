// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import registerFieldPolicy from '#shared/server/apollo/cache/utils/registerFieldPolicy.ts'

import type { InMemoryCacheConfig } from '@apollo/client/cache'

export default function register(config: InMemoryCacheConfig) {
  return registerFieldPolicy(config, 'KnowledgeBaseAnswer', {
    // The server always sends both lists complete, so an incoming one replaces the cached one:
    //   a foreign save can take a file or a schedule away, which merging would keep.
    attachments: { merge: false },
    visibilitySchedules: { merge: false },
  })
}
