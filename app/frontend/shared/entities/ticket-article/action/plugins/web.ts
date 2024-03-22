// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticleActionPlugin, TicketArticleType } from './types.ts'

const actionPlugin: TicketArticleActionPlugin = {
  order: 100,

  addTypes() {
    const type: TicketArticleType = {
      apps: ['mobile'],
      value: 'web',
      label: __('Web'),
      icon: 'web',
      view: {
        customer: ['change'],
      },
      fields: {
        attachments: {},
      },
      internal: false,
    }
    return [type]
  },
}

export default actionPlugin
