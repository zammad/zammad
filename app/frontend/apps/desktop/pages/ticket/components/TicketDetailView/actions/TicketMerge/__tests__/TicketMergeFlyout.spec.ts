// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import renderComponent, {
  getTestRouter,
} from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { waitForTicketMergeMutationCalls } from '#shared/entities/ticket/graphql/mutations/merge.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import TicketMergeFlyout from '#desktop/pages/ticket/components/TicketDetailView/actions/TicketMerge/TicketMergeFlyout.vue'
import { mockTicketRelationAndRecentTicketListsQuery } from '#desktop/pages/ticket/graphql/queries/ticketRelationAndRecentTicketLists.mocks.ts'

describe('TicketMergeFlyout', () => {
  it('renders UI correctly', async () => {
    mockTicketRelationAndRecentTicketListsQuery({
      ticketsRecentlyViewed: [createDummyTicket()],
      ticketsRecentByCustomer: [createDummyTicket()],
    })

    mockApplicationConfig({
      ticket_hook: 'Hook#',
    })

    const wrapper = renderComponent(TicketMergeFlyout, {
      props: {
        ticket: createDummyTicket(),
        name: 'TicketMergeFlyout',
      },
      form: true,
      flyout: true,
      router: true,
    })

    expect(
      wrapper.getByRole('heading', { name: 'Merge Tickets', level: 2 }),
    ).toBeInTheDocument()

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

    // Rest is already tested in TicketTable
  })

  it('should select ticket on row click and submit ticket merge', async () => {
    mockTicketRelationAndRecentTicketListsQuery({
      ticketsRecentlyViewed: [createDummyTicket()],
      ticketsRecentByCustomer: [createDummyTicket()],
    })

    const ticket = createDummyTicket({ title: 'bar' })

    const wrapper = renderComponent(TicketMergeFlyout, {
      props: {
        ticket,
        name: 'TicketMergeFlyout',
      },
      form: true,
      flyout: true,
      router: true,
    })

    expect(
      await wrapper.findByRole('heading', {
        name: 'Recent Customer Tickets',
        level: 3,
      }),
    ).toBeInTheDocument()

    const rows = wrapper.getAllByLabelText('Select table row')

    await wrapper.events.click(rows[0])

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Merge' }))

    const calls = await waitForTicketMergeMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      sourceTicketId: ticket.id,
      targetTicketId: 'gid://zammad/Ticket/1',
    })

    expect(getTestRouter().currentRoute.value.fullPath).toBe('/ticket/1')
  })
})
