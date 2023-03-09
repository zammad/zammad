// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticleActionPlugin, TicketArticleType } from './types'

const actionPlugin: TicketArticleActionPlugin = {
  order: 100,

  addTypes() {
    const type: TicketArticleType = {
      apps: ['mobile'],
      value: 'web',
      label: __('Web'),
      icon: {
        mobile: 'mobile-web',
      },
      view: {
        customer: ['change'],
      },
      attributes: ['attachments'],
      internal: false,
    }
    return [type]
  },
}

export default actionPlugin
