// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectClass, TicketArticle } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { textTruncate } from '#shared/utils/helpers.ts'

import HistoryEventDetailsReaction from '../HistoryEventDetails/HistoryEventDetailsReaction.vue'
import { eventEntityNames } from '../utils/historyEventEntityNames.ts'

import type { EventActionModule } from '../types.ts'

export default <EventActionModule>{
  name: 'created',
  actionName: (event) => {
    if (!event.attribute || event.attribute !== 'reaction') return 'created'

    const emoji = event.changes?.to as string

    return emoji.length > 0 ? __('Reacted with') : __('Reacted')
  },
  content: (event) => {
    const entity =
      (event.object?.__typename === 'ObjectClass'
        ? (event.object as ObjectClass).klass
        : event.object?.__typename) || __('Unknown')

    const details = (event.changes?.to || '') as string

    if (event.attribute && event.attribute === 'reaction') {
      const article = event.object as TicketArticle

      const emoji = event.changes?.to as string

      return {
        description:
          emoji.length > 0
            ? i18n.t('%s to message', emoji)
            : i18n.t('to message'),
        details: textTruncate(article.body),
        additionalDetails: i18n.t('from %s', event.changes.from),
        component: HistoryEventDetailsReaction,
      }
    }

    return {
      description: eventEntityNames[entity] || entity,
      details,
    }
  },
}
