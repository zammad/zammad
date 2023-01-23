// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticleActionPlugin, TicketArticleType } from './types'

const actionPlugin: TicketArticleActionPlugin = {
  order: 100,

  addTypes(ticket, { view, config }) {
    let internal = false
    if (view.isTicketAgent)
      internal = !!config.ui_ticket_zoom_article_note_new_internal
    const type: TicketArticleType = {
      apps: ['mobile'],
      value: 'note',
      label: __('Note'),
      icon: {
        mobile: 'mobile-note',
      },
      view: {
        agent: ['read'],
        customer: ['read'],
      },
      attributes: ['attachments'],
      internal,
    }
    return [type]
  },
}

export default actionPlugin
