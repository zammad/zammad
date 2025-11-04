// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockTicketInfoForPopoverQuery,
  waitForTicketInfoForPopoverQueryCalls,
} from '../TicketPopoverWithTrigger/graphql/queries/ticketInfoForPopover.mocks.ts'
import TicketPopoverWithTrigger, { type Props } from '../TicketPopoverWithTrigger.vue'

const dummyTicket = createDummyTicket({
  owner: {
    id: convertToGraphQLId('User', 3),
    internalId: 3,
    fullname: 'Agent 1 Test',
  },
})

const renderTicketPopover = (props?: Partial<Props>) => {
  mockTicketInfoForPopoverQuery({
    ticket: dummyTicket,
  })

  return renderComponent(TicketPopoverWithTrigger, {
    props: {
      ticket: {
        id: dummyTicket.id,
        number: dummyTicket.number,
        internalId: dummyTicket.internalId,
        state: dummyTicket.state,
        stateColorCode: dummyTicket.stateColorCode,
        title: dummyTicket.title,
      },
      ...props,
    },
    router: true,
  })
}

describe('TicketPopoverWithTrigger', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])

    mockApplicationConfig({
      ticket_hook: 'Ticket#',
    })
  })

  it('displays a label by default', () => {
    const wrapper = renderTicketPopover()

    expect(wrapper.getByRole('link', { name: dummyTicket.title })).toBeVisible()
  })

  it('shows a skeleton when ticket info is unavailable', async () => {
    const wrapper = renderTicketPopover()

    await wrapper.events.hover(wrapper.getByRole('link'))

    const popover = await wrapper.findByRole('region')

    expect(within(popover).getAllByRole('progressbar').length).toBe(12)
  })

  it('displays a ticket popover', async () => {
    const wrapper = renderTicketPopover()

    await wrapper.events.hover(wrapper.getByRole('link'))

    const calls = await waitForTicketInfoForPopoverQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      ticketId: dummyTicket.id,
    })

    const popover = await wrapper.findByRole('region')

    expect(within(popover).getByText(dummyTicket.title)).toBeVisible()
    expect(within(popover).getByRole('status', { name: 'check-circle-no' })).toHaveAttribute(
      'aria-roledescription',
      '(ticket status: open)',
    )

    expect(within(popover).getByRole('heading', { name: 'Owner' })).toBeVisible()
    expect(within(popover).getByRole('link', { name: dummyTicket.owner.fullname! })).toBeVisible()

    expect(within(popover).getByRole('heading', { name: 'Customer' })).toBeVisible()
    expect(
      within(popover).getByRole('link', { name: dummyTicket.customer.fullname! }),
    ).toBeVisible()

    expect(within(popover).getByRole('heading', { name: 'Organization' })).toBeVisible()
    expect(
      within(popover).getByRole('link', { name: dummyTicket.organization!.name! }),
    ).toBeVisible()

    expect(within(popover).getByText('Ticket#')).toBeVisible()
    expect(within(popover).getByText(dummyTicket.number)).toBeVisible()

    expect(within(popover).getByText('Created at')).toBeVisible()
    expect(within(popover).getByTestId('date-time-relative')).toBeVisible()

    expect(within(popover).getByText('Group')).toBeVisible()
    expect(within(popover).getByText(dummyTicket.group.name!)).toBeVisible()

    expect(within(popover).getByText('Priority')).toBeVisible()
    expect(within(popover).getByText(dummyTicket.priority.name)).toBeVisible()
  })
})
