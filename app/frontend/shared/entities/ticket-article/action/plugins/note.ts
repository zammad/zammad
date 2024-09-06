// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticleActionPlugin, TicketArticleType } from './types.ts'

const actionPlugin: TicketArticleActionPlugin = {
  order: 100,

  addTypes(ticket, { config }) {
    const isInternal = !!config.ui_ticket_zoom_article_note_new_internal

    const type: TicketArticleType = {
      apps: ['mobile', 'desktop'],
      value: 'note',
      label: __('Note'),
      buttonLabel: isInternal ? __('Add internal note') : __('Add note'),
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
      internal: isInternal,
    }
    return [type]
  },
}

export default actionPlugin
