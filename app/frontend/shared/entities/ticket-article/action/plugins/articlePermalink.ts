// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useBaseUrl } from '#shared/composables/useBaseUrl.ts'
import { useCopyToClipboard } from '#shared/composables/useCopyToClipboard.ts'

import type { TicketArticleActionPlugin, TicketArticleAction } from './types.ts'

const actionPlugin: TicketArticleActionPlugin = {
  order: 900,

  addActions(ticket, article) {
    const action: TicketArticleAction = {
      apps: ['desktop'],
      label: __('Copy article permalink'),
      name: 'article-permalink',
      icon: 'files',
      view: {
        agent: ['read'],
        customer: ['read'],
      },
      link: `/tickets/${ticket.internalId}/${article.internalId}`,
      perform: () => {
        const { baseUrl } = useBaseUrl()
        const { copyToClipboard } = useCopyToClipboard()

        copyToClipboard(
          `${baseUrl.value}/desktop/tickets/${ticket.internalId}/${article.internalId}`,
        )
      },
    }

    return [action]
  },
}

export default actionPlugin
