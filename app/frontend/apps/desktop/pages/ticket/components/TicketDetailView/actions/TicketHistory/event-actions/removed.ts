// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticle } from '#shared/graphql/types.ts'
import { capitalize } from '#shared/utils/formatter.ts'
import { textTruncate } from '#shared/utils/helpers.ts'

import HistoryEventDetailsReaction from '../HistoryEventDetails/HistoryEventDetailsReaction.vue'
import { getEntityNameFromObject } from '../utils/eventHelpers.ts'

import type { EventActionModule } from '../types.ts'

export default <EventActionModule>{
  name: 'removed',
  actionName: (event) => {
    if (event.attribute && event.attribute === 'reaction') {
      return 'removed-reaction'
    }
    return 'removed'
  },
  content: (event) => {
    if (event.attribute && event.attribute === 'reaction') {
      const article = event.object as TicketArticle

      return {
        details: textTruncate(article.body),
        additionalDetails: event.changes.from,
        component: HistoryEventDetailsReaction,
      }
    }

    const details = (event.changes?.to || '') as string

    return {
      entityName: getEntityNameFromObject(event.object),
      attributeName: event.attribute ? capitalize(event.attribute) : '',
      details,
    }
  },
}
