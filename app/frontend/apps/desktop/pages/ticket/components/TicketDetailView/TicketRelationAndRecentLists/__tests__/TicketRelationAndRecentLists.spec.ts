// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TicketRelationAndRecentLists from '#desktop/pages/ticket/components/TicketDetailView/TicketRelationAndRecentLists/TicketRelationAndRecentLists.vue'
import { mockTicketRelationAndRecentTicketListsQuery } from '#desktop/pages/ticket/graphql/queries/ticketRelationAndRecentTicketLists.mocks.ts'

describe('TicketSimpleTableWrapper', () => {
  it('displays a table with ticket data', async () => {
    mockApplicationConfig({
      ticket_hook: 'Hook#',
    })

    mockTicketRelationAndRecentTicketListsQuery({
      ticketsRecentlyViewed: [createDummyTicket()],
      ticketsRecentByCustomer: [
        createDummyTicket({
          title: 'Foo Car',
          ticketId: '1111',
        }),
      ],
    })

    const wrapper = renderComponent(TicketRelationAndRecentLists, {
      props: {
        customerId: convertToGraphQLId('User', 3),
        internalTicketId: 1,
      },
      router: true,
      form: true,
    })

    expect(
      await wrapper.findByRole('heading', {
        name: 'Recent Customer Tickets',
        level: 3,
      }),
    ).toBeInTheDocument()

    expect(
      wrapper.getByRole('heading', {
        name: 'Recently Viewed Tickets',
        level: 3,
      }),
    ).toBeInTheDocument()

    expect(wrapper.getByText('Foo Car')).toBeInTheDocument()
  })
})
