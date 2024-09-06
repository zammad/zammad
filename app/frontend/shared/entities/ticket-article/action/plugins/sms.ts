// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'

import type {
  TicketArticleAction,
  TicketArticleActionPlugin,
  TicketArticleType,
} from './types.ts'

const actionPlugin: TicketArticleActionPlugin = {
  order: 300,

  addActions(ticket, article) {
    if (
      article.sender?.name !== EnumTicketArticleSenderName.Customer ||
      article.type?.name !== 'sms'
    )
      return []
    const action: TicketArticleAction = {
      apps: ['mobile', 'desktop'],
      label: __('Reply'),
      name: 'sms',
      icon: 'reply',
      view: {
        agent: ['change'],
      },
      perform(ticket, article, { openReplyForm }) {
        const from = article.from?.raw
        const articleData = {
          articleType: 'sms',
          to: from ? [from] : [],
          inReplyTo: article.messageId,
        }

        openReplyForm(articleData)
      },
    }
    return [action]
  },

  addTypes(ticket) {
    const descriptionType = ticket.createArticleType?.name
    if (descriptionType !== 'sms') return []
    const type: TicketArticleType = {
      apps: ['mobile', 'desktop'],
      value: 'sms',
      label: __('Sms'),
      buttonLabel: __('Add sms'),
      icon: 'message',
      view: {
        agent: ['change'],
      },
      internal: false,
      contentType: 'text/plain',
      fields: {
        body: {
          required: true,
          validation: 'length:1,160',
        },
        to: {},
      },
      options: {
        recipientContact: 'phone',
      },
      editorMeta: {
        footer: {
          maxlength: 160,
          warningLength: 30,
        },
      },
      performReply(ticket) {
        const { preferences } = ticket
        return {
          to: [preferences?.sms?.originator || preferences?.sms?.From],
        }
      },
    }
    return [type]
  },
}

export default actionPlugin
