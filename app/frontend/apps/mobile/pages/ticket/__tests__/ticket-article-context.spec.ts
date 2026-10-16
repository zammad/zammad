// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import type { TicketView } from '#shared/entities/ticket/types.ts'
import { replyToEmail } from '#shared/entities/ticket-article/action/plugins/email/reply.ts'

import { defaultArticles, mockTicketDetailViewGql } from './mocks/detail-view.ts'

vi.mock('#shared/entities/ticket-article/action/plugins/email/reply.ts', () => ({
  replyToEmail: vi.fn(),
}))

beforeAll(async () => {
  await import('../components/TicketDetailView/ArticleMetadataDialog.vue')
})

describe('actions inside article context', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
  })

  test('opens metadata', async () => {
    const { waitUntilTicketLoaded } = mockTicketDetailViewGql()

    const view = await visitView('/tickets/1')

    await waitUntilTicketLoaded()

    const contextTriggers = view.getAllByRole('button', {
      name: 'Article actions',
    })

    await view.events.click(contextTriggers[0])
    await view.events.click(view.getByText('Show meta data'))

    expect(view.getByText('Meta data')).toBeInTheDocument()
    expect(view.getByRole('region', { name: 'Created' })).toHaveTextContent(/2022-01-29 00:00/)

    // content is tested inside unit test
  })

  test.each<[TicketView, boolean]>([
    ['agent', true],
    ['customer', false],
  ])('shows the detected language in the %s view: %s', async (ticketView, shown) => {
    const articles = defaultArticles()
    articles.firstArticles!.edges[0].node.detectedLanguage = 'de'

    const { waitUntilTicketLoaded } = mockTicketDetailViewGql({ ticketView, articles })

    const view = await visitView('/tickets/1')

    await waitUntilTicketLoaded()

    await view.events.click(view.getAllByRole('button', { name: 'Article actions' })[0])
    await view.events.click(view.getByText('Show meta data'))

    expect(view.getByText('Meta data')).toBeInTheDocument()
    expect(!!view.queryByRole('region', { name: 'Detected language' })).toBe(shown)
  })

  test('keeps the article actions trigger busy while an action awaits the server', async () => {
    let resolveReply!: () => void

    vi.mocked(replyToEmail).mockReturnValueOnce(
      new Promise<void>((resolve) => {
        resolveReply = resolve
      }),
    )

    const articles = defaultArticles()
    articles.firstArticles!.edges[0].node.type!.name = 'email'

    const { waitUntilTicketLoaded } = mockTicketDetailViewGql({ articles })

    const view = await visitView('/tickets/1')

    await waitUntilTicketLoaded()

    const [trigger] = view.getAllByRole('button', {
      name: 'Article actions',
    })

    await view.events.click(trigger)
    await view.events.click(view.getByText('Reply'))

    expect(trigger).toHaveAttribute('aria-busy', 'true')
    expect(trigger).toBeDisabled()

    resolveReply()

    await waitFor(() => expect(trigger).not.toHaveAttribute('aria-busy', 'true'))
    expect(trigger).toBeEnabled()
  })
})
