// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@shared/i18n'
import type { TicketArticle } from '@shared/graphql/types'
import type { ActivityMessageBuilder } from '../types'

const path = (metaObject: TicketArticle) => {
  return `tickets/${metaObject.ticket.internalId}`
}

const messageText = (
  type: string,
  authorName: string,
  metaObject: TicketArticle,
): Maybe<string> => {
  const objectTitle = metaObject.ticket.title || '-'

  switch (type) {
    case 'create':
      return i18n.t('%s created article for |%s|', authorName, objectTitle)
    case 'update':
      return i18n.t('%s updated article for |%s|', authorName, objectTitle)
    default:
      return null
  }
}

export default <ActivityMessageBuilder>{
  messageText,
  path,
  model: 'Ticket::Article',
}
