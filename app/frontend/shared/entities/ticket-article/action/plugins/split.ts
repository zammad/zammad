// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticleActionPlugin, TicketArticleAction } from './types'

const actionPlugin: TicketArticleActionPlugin = {
  order: 700,

  addActions(ticket, article) {
    const action: TicketArticleAction = {
      apps: ['mobile'],
      label: __('Split'),
      name: 'split',
      icon: { mobile: 'mobile-split' },
      view: {
        agent: ['change'],
      },
      link: `/tickets/create?ticket_id=${ticket.id}&article_id=${article.id}`,
    }
    return [action]
  },
}

export default actionPlugin
