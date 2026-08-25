// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { mockTicketArticleEmailForwardReplyMutation } from '#shared/entities/ticket-article/graphql/mutations/ticketArticleEmailForwardReply.mocks.ts'
import type { ConfigList } from '#shared/types/store.ts'

import { replyToEmail } from '../email/reply.ts'
import { getReplyQuoteHeader } from '../email/selection.ts'

import { createEligibleTicketArticleReplyData, createTicketArticle } from './utils.ts'

import type { TicketArticlePerformOptions } from '../types.ts'

const createConfig = (overrides: Record<string, unknown> = {}) =>
  ({
    ui_ticket_zoom_article_email_full_quote_header: true,
    ...overrides,
  }) as unknown as ConfigList

describe('getReplyQuoteHeader', () => {
  const article = createTicketArticle({
    createdAt: '2026-08-20T10:00:00Z',
    author: { firstname: 'Max', lastname: 'Mustermann', fullname: 'max@example.com' },
  }) as TicketArticle

  it('returns nothing when the quote header setting is disabled', () => {
    const config = createConfig({ ui_ticket_zoom_article_email_full_quote_header: false })

    expect(getReplyQuoteHeader(config, article, 'Some Group')).toBe('')
  })

  it('uses the server provided sender format aware author name', () => {
    const header = getReplyQuoteHeader(createConfig(), article, 'Some Group')

    expect(header).toContain('Some Group wrote:')
    expect(header).not.toContain('Max Mustermann')
  })

  it('falls back to the author name parts, never to fullname', () => {
    const header = getReplyQuoteHeader(createConfig(), article)

    expect(header).toContain('Max Mustermann wrote:')
    expect(header).not.toContain('max@example.com')
  })

  // Simulates a failed mutation or a nameless customer author (the server
  //   returns no name then): the client must never fall back to fullname,
  //   which holds the email address for users without a name.
  it('renders a blank name instead of the email address when no server name is available', () => {
    const namelessArticle = createTicketArticle({
      createdAt: '2026-08-20T10:00:00Z',
      author: { firstname: null, lastname: null, fullname: 'nameless@example.com' },
    }) as TicketArticle

    const header = getReplyQuoteHeader(createConfig(), namelessArticle)

    expect(header).toContain('wrote:')
    expect(header).not.toContain('nameless@example.com')
  })
})

describe('replyToEmail citation', () => {
  it('inserts the server provided author name into the quoted body', async () => {
    const { ticket, article } = createEligibleTicketArticleReplyData('email')

    mockTicketArticleEmailForwardReplyMutation({
      ticketArticleEmailForwardReply: {
        quotableAuthorName: 'Sender Format Name',
      },
    })

    const openReplyForm = vi.fn()
    const options = {
      openReplyForm,
      getNewArticleBody: () => '',
    } as unknown as TicketArticlePerformOptions

    const config = createConfig({ ui_ticket_zoom_article_email_full_quote: true })

    await replyToEmail(ticket, article as TicketArticle, options, config)

    expect(openReplyForm).toHaveBeenCalledWith(
      expect.objectContaining({
        body: expect.stringContaining('Sender Format Name wrote:'),
      }),
    )
  })
})
