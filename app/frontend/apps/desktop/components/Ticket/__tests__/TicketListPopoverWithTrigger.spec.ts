// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumTicketStateTypeCategory } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockTicketsByCustomerQuery,
  waitForTicketsByCustomerQueryCalls,
} from '#desktop/entities/ticket/graphql/queries/ticketsByCustomer.mocks.ts'

import TicketListPopoverWithTrigger, { type Props } from '../TicketListPopoverWithTrigger.vue'

const dummyTickets = Array.from({ length: 7 }, () => createDummyTicket())

const dummyFilters = {
  customerId: convertToGraphQLId('User', 2),
  stateTypeCategory: EnumTicketStateTypeCategory.Open,
}

const renderTicketListPopover = (props?: Partial<Props>) => {
  mockTicketsByCustomerQuery({
    ticketsByCustomer: {
      totalCount: 10,
      edges: dummyTickets.map((ticket) => ({
        node: ticket,
      })),
    },
  })

  return renderComponent(TicketListPopoverWithTrigger, {
    props: {
      filters: dummyFilters,
      title: 'Open Tickets',
      ...props,
    },
    router: true,
  })
}

describe('TicketListPopoverWithTrigger', () => {
  it('displays a label by default', () => {
    const wrapper = renderTicketListPopover()
    expect(wrapper.getByText('Open Tickets')).toBeVisible()
  })

  it('displays a ticket list popover', async () => {
    const wrapper = renderTicketListPopover()

    await wrapper.events.hover(wrapper.getByText('Open Tickets'))

    const calls = await waitForTicketsByCustomerQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      customerId: dummyFilters.customerId,
      stateTypeCategory: dummyFilters.stateTypeCategory,
      pageSize: 7,
    })

    const popover = await wrapper.findByRole('region')

    expect(within(popover).getByText('Open Tickets')).toBeVisible()

    dummyTickets.forEach(async (ticket) => {
      expect(await within(popover).findByRole('link', { name: ticket.title })).toHaveAttribute(
        'href',
        `/tickets/${ticket.internalId}`,
      )

      wrapper.debug(popover)
    })

    expect(await wrapper.findByRole('button', { name: 'Show more' })).toBeInTheDocument()
  })
})
