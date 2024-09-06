// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  TicketArticleAction,
  TicketArticleActionPlugin,
  TicketArticleType,
} from './types.ts'

const actionPlugin: TicketArticleActionPlugin = {
  order: 300,

  addActions(ticket, article) {
    const type = article.type?.name

    if (type !== 'facebook feed comment' && type !== 'facebook feed post')
      return []

    const action: TicketArticleAction = {
      apps: ['mobile', 'desktop'],
      label: __('Reply'),
      name: type,
      icon: 'reply',
      view: {
        agent: ['change'],
      },
      perform(ticket, article, { openReplyForm }) {
        const articleData = {
          // always a comment, doesn't depend on current article type
          articleType: 'facebook feed comment',
          body: '',
          inReplyTo: null,
        }

        openReplyForm(articleData)
      },
    }
    return [action]
  },

  addTypes(ticket) {
    const descriptionType = ticket.createArticleType?.name

    if (descriptionType !== 'facebook feed post') return []

    const type: TicketArticleType = {
      apps: ['mobile', 'desktop'],
      value: 'facebook feed comment',
      label: __('Facebook'),
      buttonLabel: __('Add comment'),
      icon: 'facebook',
      view: {
        agent: ['change'],
      },
      fields: {},
      internal: false,
      contentType: 'text/plain',
    }
    return [type]
  },
}

export default actionPlugin
