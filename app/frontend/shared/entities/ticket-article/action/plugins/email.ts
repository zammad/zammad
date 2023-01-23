// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticleActionPlugin, TicketArticleType } from './types'

const actionPlugin: TicketArticleActionPlugin = {
  order: 200,

  // TODO mocked
  addTypes(ticket, { config }) {
    // TODO
    // if (!ticket.group.email_address_id) return []

    const attributes = new Set([
      'to',
      'cc',
      'subject',
      'attachments',
      'security',
    ])

    if (!config.ui_ticket_zoom_article_email_subject)
      attributes.delete('subject')

    const type: TicketArticleType = {
      value: 'email',
      label: __('Email'),
      apps: ['mobile'],
      icon: {
        mobile: 'mobile-phone',
      },
      attributes: Array.from(attributes),
      view: {
        agent: ['change'],
      },
      onDeselected() {
        console.log('deselected')
      },
      onSelected() {
        console.log('selected')
      },
      internal: false,
    }
    return [type]
  },
}

export default actionPlugin
