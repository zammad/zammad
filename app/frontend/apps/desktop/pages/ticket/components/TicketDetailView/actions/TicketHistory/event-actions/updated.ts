// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import {
  EnumObjectManagerObjects,
  type TicketArticle,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { isDateString, validDateTime } from '#shared/utils/datetime.ts'
import { textTruncate } from '#shared/utils/helpers.ts'

import HistoryEventDetailsReaction from '../HistoryEventDetails/HistoryEventDetailsReaction.vue'
import { getEntityFromObject } from '../utils/eventHelpers.ts'
import { eventEntityNames } from '../utils/historyEventEntityNames.ts'

import type { EventActionModule } from '../types.ts'

export default <EventActionModule>{
  name: 'updated',
  actionName: (event) => {
    if (!event.attribute || event.attribute !== 'reaction') return 'updated'

    const emoji = event.changes?.to as string

    return emoji.length > 0 ? 'changed-reaction-to' : 'changed-reaction'
  },
  // eslint-disable-next-line sonarjs/cognitive-complexity
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

    let displayName = attributeName
    let needsTranslation = false

    if (entity in EnumObjectManagerObjects) {
      const { attributesLookup: objectAttributesLookup } = useObjectAttributes(
        EnumObjectManagerObjects[
          entity as keyof typeof EnumObjectManagerObjects
        ],
      )

      if (attributeName) {
        const objectAttribute =
          objectAttributesLookup.value.get(`${attributeName}_id`) ||
          objectAttributesLookup.value.get(attributeName)

        needsTranslation = objectAttribute?.dataOption?.translate ?? false

        if (objectAttribute?.display) displayName = objectAttribute?.display
      }
    }

    if (validDateTime(details) || validDateTime(additionalDetails)) {
      const dateFormatFunction =
        isDateString(details) || isDateString(additionalDetails)
          ? 'date'
          : 'dateTime'

      if (details !== '-') {
        details = i18n[dateFormatFunction](details)
      }
      if (additionalDetails !== '-') {
        additionalDetails = i18n[dateFormatFunction](additionalDetails)
      }
    } else if (needsTranslation) {
      details = i18n.t(details)
      additionalDetails = i18n.t(additionalDetails)
    }

    if (attributeName === 'group') {
      details = details.replace('::', ' › ')
      additionalDetails = additionalDetails.replace('::', ' › ')
    }

    return {
      entityName: eventEntityNames[entity] || entity,
      attributeName: displayName,
      details,
      additionalDetails,
      showSeparator: details.length > 0 && additionalDetails.length > 0,
    }
  },
}
