// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticleActionPlugin, TicketArticleType } from './types.ts'

const actionPlugin: TicketArticleActionPlugin = {
  order: 100,

  addTypes(ticket, { config }) {
    const type: TicketArticleType = {
      apps: ['mobile'],
      value: 'note',
      label: __('Note'),
      icon: 'note',
      fields: {
        attachments: {},
        body: {
          required: true,
        },
      },
      view: {
        agent: ['change'],
      },
      internal: !!config.ui_ticket_zoom_article_note_new_internal,
    }
    return [type]
  },
}

export default actionPlugin
