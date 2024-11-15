// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import { mockTicketRelationAndRecentTicketListsQuery } from '#desktop/pages/ticket/graphql/queries/ticketRelationAndRecentTicketLists.mocks.ts'

import { mockLinkListQuery } from '../../graphql/queries/linkList.mocks.ts'

describe('Ticket detail view ticket merge', () => {
  it('allows to merge source ticket with a target ticket', async () => {
    mockPermissions(['ticket.agent'])

    mockTicketRelationAndRecentTicketListsQuery({
      ticketsRecentlyViewed: [createDummyTicket()],
      ticketsRecentByCustomer: [
        createDummyTicket({
          title: 'Foo Car',
          ticketId: '1111',
        }),
      ],
    })

    await mockApplicationConfig({
      time_accounting_types: true,
    })

    const ticket = createDummyTicket()

    mockTicketQuery({
      ticket,
    })

    mockLinkListQuery({
      linkList: [],
    })

    const view = await visitView('/tickets/1')

    const sidebar = view.getByLabelText('Content sidebar')

    await view.events.click(
      within(sidebar).getByRole('button', { name: 'Action menu button' }),
    )

    await view.events.click(await view.findByRole('button', { name: 'Merge' }))

    expect(
      await view.findByRole('heading', { name: 'Merge Tickets', level: 2 }),
    ).toBeInTheDocument()

    expect(await view.findByText('Recent Customer Tickets')).toBeInTheDocument()
    expect(view.getByText('Recently Viewed Tickets')).toBeInTheDocument()
    expect(view.getByText('Foo Car')).toBeInTheDocument()
  })
})
