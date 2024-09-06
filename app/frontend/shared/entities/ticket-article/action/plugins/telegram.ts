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
    const sender = article.sender?.name
    const type = article.type?.name

    if (
      sender !== EnumTicketArticleSenderName.Customer ||
      type !== 'telegram personal-message'
    )
      return []

    const action: TicketArticleAction = {
      apps: ['mobile', 'desktop'],
      label: __('Reply'),
      name: 'telegram personal-message',
      icon: 'reply',
      view: {
        agent: ['change'],
      },
      perform(ticket, article, { openReplyForm }) {
        const articleData = {
          articleType: type,
          inReplyTo: article.messageId,
        }

        openReplyForm(articleData)
      },
    }
    return [action]
  },

  addTypes(ticket) {
    const descriptionType = ticket.createArticleType?.name

    if (descriptionType !== 'telegram personal-message') return []

    const type: TicketArticleType = {
      apps: ['mobile', 'desktop'],
      value: 'telegram personal-message',
      label: __('Telegram'),
      buttonLabel: __('Add message'),
      icon: 'telegram',
      view: {
        agent: ['change'],
      },
      internal: false,
      contentType: 'text/plain',
      fields: {
        body: {
          required: true,
          validation: 'length:1,10000',
        },
        attachments: {},
      },
      editorMeta: {
        footer: {
          maxlength: 10000,
          warningLength: 5000,
        },
      },
    }
    return [type]
  },
}

export default actionPlugin
