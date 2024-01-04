// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticleActionPlugin, TicketArticleAction } from './types.ts'

const actionPlugin: TicketArticleActionPlugin = {
  order: 700,

  addActions(ticket, article) {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
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

    // TODO: Return an empty array until the support for splitting articles is implemented in the ticket create screen.
    return []
  },
}

export default actionPlugin
