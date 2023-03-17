// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Ticket } from '@shared/graphql/types'
import { i18n } from '@shared/i18n'
import type { ActivityMessageBuilder } from '../types'

const path = (metaObject: Ticket) => {
  return `tickets/${metaObject.internalId}`
}

const messageText = (
  type: string,
  authorName: string,
  metaObject: Ticket,
): Maybe<string> => {
  const objectTitle = metaObject.title || '-'

  switch (type) {
    case 'create':
      return i18n.t('%s created ticket |%s|', authorName, objectTitle)
    case 'update':
      return i18n.t('%s updated ticket |%s|', authorName, objectTitle)
    case 'reminder_reached':
      return i18n.t('Pending reminder reached for ticket |%s|', objectTitle)
    case 'escalation':
      return i18n.t('Ticket |%s| has escalated!', objectTitle)
    case 'escalation_warning':
      return i18n.t('Ticket |%s| will escalate soon!', objectTitle)
    case 'update.merged_into':
      return i18n.t('Ticket |%s| was merged into another ticket', objectTitle)
    case 'update.received_merge':
      return i18n.t('Another ticket was merged into ticket |%s|', objectTitle)
    default:
      return null
  }
}

export default <ActivityMessageBuilder>{
  path,
  messageText,
  model: 'Ticket',
}
