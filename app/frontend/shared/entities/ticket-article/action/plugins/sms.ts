// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type {
  TicketArticleAction,
  TicketArticleActionPlugin,
  TicketArticleType,
} from './types'

const actionPlugin: TicketArticleActionPlugin = {
  order: 300,

  addActions(ticket, article) {
    if (article.sender?.name !== 'Customer' || article.type?.name !== 'sms')
      return []
    const action: TicketArticleAction = {
      apps: ['mobile'],
      label: __('Reply'),
      name: 'sms',
      icon: {
        mobile: 'mobile-reply',
      },
      view: {
        agent: ['change'],
      },
      perform(ticket, article, { openReplyDialog }) {
        const from = article.from?.raw
        const articleData = {
          articleType: 'sms',
          to: from ? [from] : [],
          inReplyTo: article.messageId,
        }

        openReplyDialog(articleData)
      },
    }
    return [action]
  },

  addTypes(ticket) {
    const descriptionType = ticket.createArticleType?.name
    if (descriptionType !== 'sms') return []
    const type: TicketArticleType = {
      apps: ['mobile'],
      value: 'sms',
      label: __('Sms'),
      icon: {
        mobile: 'mobile-message',
      },
      view: {
        agent: ['change'],
      },
      attributes: ['to'],
      internal: false,
      recipientContact: 'phone',
      contentType: 'text/plain',
      editorMeta: {
        footer: {
          maxlength: 160,
          warningLength: 30,
        },
      },
    }
    return [type]
  },
}

export default actionPlugin
