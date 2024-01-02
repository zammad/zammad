// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockTicketOverviews } from '#tests/support/mocks/ticket-overviews.ts'

describe('testing home section menu', () => {
  beforeEach(() => {
    mockTicketOverviews()
  })

  it('not show ticket overview section menu item without permission', async () => {
    const view = await visitView('/')

    expect(
      view.queryByRole('link', {
        name: 'Ticket Overviews',
      }),
    ).not.toBeInTheDocument()
  })

  it('show ticket overview section menu item', async () => {
    mockPermissions(['ticket.agent'])

    const view = await visitView('/')

    const ticketOverviewLink = view.getByRole('link', {
      name: 'Ticket Overviews',
    })

    expect(ticketOverviewLink).toHaveAttribute('href', '/mobile/tickets/view')
  })
})
