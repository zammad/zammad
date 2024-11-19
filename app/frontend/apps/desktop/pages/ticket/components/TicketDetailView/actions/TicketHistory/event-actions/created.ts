// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticle } from '#shared/graphql/types.ts'
import { textTruncate } from '#shared/utils/helpers.ts'

import HistoryEventDetailsReaction from '../HistoryEventDetails/HistoryEventDetailsReaction.vue'
import { getEntityNameFromObject } from '../utils/eventHelpers.ts'

import type { EventActionModule } from '../types.ts'

export default <EventActionModule>{
  name: 'created',
  actionName: (event) => {
    if (!event.attribute || event.attribute !== 'reaction') return 'created'

    const emoji = event.changes?.to as string

    return emoji.length > 0 ? 'reacted-with' : 'reacted'
  },
  content: (event) => {
    if (event.attribute && event.attribute === 'reaction') {
      const article = event.object as TicketArticle

      const emoji = event.changes?.to as string

      return {
        description: emoji,
        details: textTruncate(article.body),
        additionalDetails: event.changes.from,
        component: HistoryEventDetailsReaction,
      }
    }

    const details = (event.changes?.to || '') as string

    return {
      entityName: getEntityNameFromObject(event.object),
      details,
    }
  },
}
