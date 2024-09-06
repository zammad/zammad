// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { setupView } from '#tests/support/mock-user.ts'

import { type TicketView } from '#shared/entities/ticket/types.ts'

import {
  createTicketArticle,
  createTestArticleActions,
  createTicket,
} from './utils.ts'

import type { TicketArticlePerformOptions } from '../types.ts'

const copyToClipboardMock = vi.fn()

vi.mock('#shared/composables/useCopyToClipboard.ts', async () => ({
  useCopyToClipboard: () => ({ copyToClipboard: copyToClipboardMock }),
}))

describe('article permanent link action', () => {
  it.each([
    {
      user: 'agent' as TicketView,
      policy: { agentReadAccess: true },
    },

    {
      user: 'customer' as TicketView,
      policy: { update: true },
    },
  ])('returns article permanent link for $user', ({ user, policy }) => {
    setupView(user)
    const ticket = createTicket({ policy })
    const article = createTicketArticle()
    const actions = createTestArticleActions(ticket, article, 'desktop')

    expect(actions).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          name: 'article-permalink',
          link: `/tickets/${ticket.internalId}/${article.internalId}`,
        }),
      ]),
    )
  })

  it('copies article permalink to clipboard on perform action', () => {
    mockApplicationConfig({ http_type: 'https', fqdn: 'example.com' })
    setupView('agent')
    const ticket = createTicket({ policy: { agentReadAccess: true } })
    const article = createTicketArticle()
    const actions = createTestArticleActions(ticket, article, 'desktop')

    const articlePermalink = actions.find(
      (action) => action.name === 'article-permalink',
    )

    articlePermalink?.perform?.(
      ticket,
      article,
      {} as TicketArticlePerformOptions,
    )

    expect(copyToClipboardMock).toHaveBeenCalledWith(
      `https://example.com/desktop/tickets/${ticket.internalId}/${article.internalId}`,
    )
  })
})
