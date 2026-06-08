// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { type TicketArticle } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { validDateTime } from '#shared/utils/datetime.ts'
import { textTruncate } from '#shared/utils/helpers.ts'

import HistoryEventDetailsReaction from '../HistoryEventDetails/HistoryEventDetailsReaction.vue'
import { getEntityFromObject } from '../utils/eventHelpers.ts'
import {
  attributeNeedsTranslation,
  formatDateOrDateTime,
  formatGroup,
  getDisplayName,
} from '../utils/eventValueFormatters.ts'
import { eventEntityNames } from '../utils/historyEventEntityNames.ts'

import type { EventActionModule } from '../types.ts'

export default <EventActionModule>{
  name: 'updated',
  actionName: (event) => {
    if (!event.attribute || event.attribute !== 'reaction') return 'updated'

    const emoji = event.changes?.to as string

    return emoji.length > 0 ? 'changed-reaction-to' : 'changed-reaction'
  },
  content: (event) => {
    const { attribute: attributeName } = event

    if (attributeName === 'reaction') {
      const article = event.object as TicketArticle

      const emoji = event.changes?.to as string

      return {
        description: emoji,
        details: textTruncate(article.body),
        additionalDetails: event.changes.from,
        component: HistoryEventDetailsReaction,
      }
    }

    const entity = getEntityFromObject(event.object)

    let details = (event.changes?.from || '-') as string
    let additionalDetails = (event.changes?.to || '-') as string

    if (validDateTime(details) || validDateTime(additionalDetails)) {
      details = formatDateOrDateTime(details)
      additionalDetails = formatDateOrDateTime(additionalDetails)
    } else if (attributeNeedsTranslation(event)) {
      details = i18n.t(details)
      additionalDetails = i18n.t(additionalDetails)
    }

    details = formatGroup(attributeName, details)
    additionalDetails = formatGroup(attributeName, additionalDetails)

    return {
      entityName: eventEntityNames[entity] || entity,
      attributeName: getDisplayName(event),
      details,
      additionalDetails,
      showSeparator: details.length > 0 && additionalDetails.length > 0,
    }
  },
}
