// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  TicketArticleAction,
  TicketArticleActionPlugin,
  TicketArticleType,
} from './types.ts'

const actionPlugin: TicketArticleActionPlugin = {
  order: 300,

  addActions(ticket, article) {
    const sender = article.sender?.name // Customer || Agent
    const type = article.type?.name // 'whatsapp message'

    if (sender !== 'Customer' || type !== 'whatsapp message') return []

    const action: TicketArticleAction = {
      apps: ['mobile'],
      label: __('Reply'),
      name: 'whatsapp message',
      icon: 'reply',
      view: {
        agent: ['change'],
      },
      perform(ticket, article, { openReplyDialog }) {
        const articleData = {
          articleType: type,
          inReplyTo: article.messageId,
        }
        openReplyDialog(articleData)
      },
    }

    return [action]
  },

  addTypes(ticket) {
    const descriptionType = ticket.createArticleType?.name

    if (descriptionType !== 'whatsapp message') return []

    const type: TicketArticleType = {
      apps: ['mobile'],
      value: 'whatsapp message',
      label: __('Whatsapp'),
      icon: 'whatsapp',
      view: {
        agent: ['change'],
      },
      attributes: ['attachments'],
      internal: false,
      contentType: 'text/plain',
      validation: {
        body: 'length:1,4096',
      },
    }
    return [type]
  },
}

export default actionPlugin
