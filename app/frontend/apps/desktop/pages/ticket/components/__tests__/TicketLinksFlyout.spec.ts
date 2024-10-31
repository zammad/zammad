// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import TicketLinksFlyout from '#desktop/pages/ticket/components/TicketLinksFlyout.vue'
import { mockTicketRelationAndRecentTicketListsQuery } from '#desktop/pages/ticket/graphql/queries/ticketRelationAndRecentTicketLists.mocks.ts'

import { waitForLinkAddMutationCalls } from '../../graphql/mutations/linkAdd.mocks.ts'
import { mockLinkListQuery } from '../../graphql/queries/linkList.mocks.ts'

describe('TicketLinksFlyout', () => {
  it('renders the flyout', async () => {
    mockTicketRelationAndRecentTicketListsQuery({
      ticketsRecentlyViewed: [createDummyTicket()],
      ticketsRecentByCustomer: [createDummyTicket()],
    })

    mockLinkListQuery({
      linkList: [],
    })

    mockApplicationConfig({
      ticket_hook: 'Hook#',
    })

    const wrapper = renderComponent(TicketLinksFlyout, {
      props: {
        sourceTicket: createDummyTicket(),
      },
      form: true,
      flyout: true,
      router: true,
    })

    expect(
      wrapper.getByRole('heading', { name: 'Link Tickets', level: 2 }),
    ).toBeInTheDocument()

    expect(wrapper.getByLabelText('Link ticket')).toBeInTheDocument()
    expect(wrapper.getByLabelText('Link type')).toBeInTheDocument()

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
  })

  it('can select a ticket and link it', async () => {
    mockTicketRelationAndRecentTicketListsQuery({
      ticketsRecentlyViewed: [createDummyTicket()],
      ticketsRecentByCustomer: [createDummyTicket()],
    })

    mockLinkListQuery({
      linkList: [],
    })

    const ticket = createDummyTicket({ title: 'bar' })

    const wrapper = renderComponent(TicketLinksFlyout, {
      props: {
        sourceTicket: createDummyTicket(),
      },
      form: true,
      flyout: true,
      router: true,
    })

    await waitForNextTick()

    const rows = wrapper.getAllByLabelText('Select table row')

    await wrapper.events.click(rows[0])

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Link' }))

    const calls = await waitForLinkAddMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: {
        sourceId: ticket.id,
        targetId: 'gid://zammad/Ticket/1',
        type: 'normal',
      },
    })
  })
})
