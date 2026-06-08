// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '#shared/i18n.ts'
import { validDateTime } from '#shared/utils/datetime.ts'

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
  name: 'set',
  actionName: 'set',
  content: (event) => {
    const { attribute: attributeName } = event

    const entity = getEntityFromObject(event.object)

    let details = (event.changes?.to || '-') as string

    if (validDateTime(details)) {
      details = formatDateOrDateTime(details)
    } else if (attributeNeedsTranslation(event)) {
      details = i18n.t(details)
    }

    details = formatGroup(attributeName, details)

    return {
      entityName: eventEntityNames[entity] || entity,
      attributeName: getDisplayName(event),
      details,
    }
  },
}
