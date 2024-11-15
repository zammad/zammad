// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import {
  EnumObjectManagerObjects,
  type ObjectClass,
  type TicketArticle,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { isDateString, validDateTime } from '#shared/utils/datetime.ts'
import { textTruncate } from '#shared/utils/helpers.ts'

import HistoryEventDetailsReaction from '../HistoryEventDetails/HistoryEventDetailsReaction.vue'
import { eventEntityNames } from '../utils/historyEventEntityNames.ts'

import type { EventActionModule } from '../types.ts'

export default <EventActionModule>{
  name: 'updated',
  actionName: (event) => {
    if (!event.attribute || event.attribute !== 'reaction') return 'updated'

    const emoji = event.changes?.to as string

    return emoji.length > 0 ? __('Changed reaction to') : __('Changed reaction')
  },
  // eslint-disable-next-line sonarjs/cognitive-complexity
  content: (event) => {
    // TODO: Refactor this function to reduce cognitive complexity.
    const entity =
      (event.object?.__typename === 'ObjectClass'
        ? (event.object as ObjectClass).klass
        : event.object?.__typename) || __('Unknown')

    let details = (event.changes?.from || '-') as string
    let additionalDetails = (event.changes?.to || '-') as string

    let description = eventEntityNames[entity] || entity

    const { attribute: attributeName } = event

    if (attributeName === 'reaction') {
      const article = event.object as TicketArticle

      const emoji = event.changes?.to as string

      return {
        description:
          emoji.length > 0
            ? i18n.t('%s on message', emoji)
            : i18n.t('on message'),
        details: textTruncate(article.body),
        additionalDetails: i18n.t('from %s', event.changes.from),
        component: HistoryEventDetailsReaction,
      }
    }

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

        displayName = objectAttribute?.display
          ? objectAttribute?.display
          : attributeName
      }
    }

    description += displayName ? ` ${displayName}` : ''

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
      description,
      details,
      additionalDetails,
      showSeparator: details.length > 0 && additionalDetails.length > 0,
    }
  },
}
