// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type {
  TicketArticleAction,
  TicketArticleActionPlugin,
  TicketArticleType,
} from './types'

const actionPlugin: TicketArticleActionPlugin = {
  order: 300,

  addActions(ticket, article) {
    const type = article.type?.name

    if (type !== 'facebook feed comment' && type !== 'facebook feed post')
      return []

    const action: TicketArticleAction = {
      apps: ['mobile'],
      label: __('Reply'),
      name: type,
      icon: { mobile: 'mobile-reply' },
      view: {
        agent: ['change'],
      },
      perform(ticket, article, { openReplyDialog }) {
        const articleData = {
          // always a comment, doesn't depend on current article type
          articleType: 'facebook feed comment',
          body: '',
          inReplyTo: null,
        }

        openReplyDialog(articleData)
      },
    }
    return [action]
  },

  addTypes(ticket) {
    const descriptionType = ticket.createArticleType?.name

    if (descriptionType !== 'facebook feed post') return []

    const type: TicketArticleType = {
      apps: ['mobile'],
      value: 'facebook feed comment',
      label: __('Facebook'),
      icon: {
        mobile: 'mobile-facebook',
      },
      view: {
        agent: ['change'],
      },
      attributes: [],
      internal: false,
      contentType: 'text/plain',
    }
    return [type]
  },
}

export default actionPlugin
