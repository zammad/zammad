// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { visitView } from '@tests/support/components/visitView'
import { mockPermissions } from '@tests/support/mock-permissions'
import { waitForNextTick } from '@tests/support/utils'

describe('testing home section menu', () => {
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

    await view.events.click(ticketOverviewLink)

    await waitForNextTick(true)

    await waitFor(() => {
      expect(view.getByText('Tickets')).toBeInTheDocument()
    })
  })
})
