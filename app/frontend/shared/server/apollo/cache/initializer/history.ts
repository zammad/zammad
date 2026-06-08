// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

export default function register(config: InMemoryCacheConfig): InMemoryCacheConfig {
  return {
    ...config,
    possibleTypes: {
      ...config.possibleTypes,

      // History union types - manually defined to avoid for now:
      // https://the-guild.dev/graphql/codegen/plugins/other/fragment-matcher
      HistoryRecordIssuer: [
        'User',
        'Trigger',
        'Job',
        'PostmasterFilter',
        'AIAgent',
        'Macro',
        'ObjectClass',
      ],
      HistoryRecordEventObject: [
        'Checklist',
        'ChecklistItem',
        'Group',
        'Mention',
        'Organization',
        'Ticket',
        'TicketArticle',
        'TicketSharedDraftZoom',
        'User',
        'ObjectClass',
      ],
    },
  }
}
