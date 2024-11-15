// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectClass, TicketArticle } from '#shared/graphql/types.ts'
import { capitalize } from '#shared/utils/formatter.ts'
import { textTruncate } from '#shared/utils/helpers.ts'

import HistoryEventDetailsReaction from '../HistoryEventDetails/HistoryEventDetailsReaction.vue'
import { eventEntityNames } from '../utils/historyEventEntityNames.ts'

import type { EventActionModule } from '../types.ts'

export default <EventActionModule>{
  name: 'removed',
  actionName: (event) => {
    if (event.attribute && event.attribute === 'reaction') {
      return __('Removed reaction')
    }
    return __('Removed')
  },
  content: (event) => {
    if (event.attribute && event.attribute === 'reaction') {
      const article = event.object as TicketArticle

      return {
        description: __('from message'),
        details: textTruncate(article.body),
        additionalDetails: `from ${event.changes.from}`,
        component: HistoryEventDetailsReaction,
      }
    }

    const entity =
      (event.object?.__typename === 'ObjectClass'
        ? (event.object as ObjectClass).klass
        : event.object?.__typename) || __('Unknown')

    const details = (event.changes?.to || '') as string

    return {
      description: event.attribute
        ? capitalize(event.attribute)
        : eventEntityNames[entity] || entity,
      details,
    }
  },
}
