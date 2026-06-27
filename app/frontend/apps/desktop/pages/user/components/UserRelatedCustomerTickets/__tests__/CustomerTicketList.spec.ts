// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'
import { flushPromises } from '@vue/test-utils'

import { renderComponent } from '#tests/support/components/index.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumTicketStateTypeCategory, type TicketEdge, type User } from '#shared/graphql/types.ts'
import emitter from '#shared/utils/emitter.ts'

import {
  mockTicketsByCustomerQuery,
  waitForTicketsByCustomerQueryCalls,
} from '#desktop/entities/ticket/graphql/queries/ticketsByCustomer.mocks.ts'

import CustomerTicketList, { type Props } from '../CustomerTicketList.vue'

import '#tests/graphql/builders/mocks.ts'

const customer: User = {
  __typename: 'User',
  id: 'gid://zammad/User/2',
  internalId: 2,
  firstname: 'Nicole',
  lastname: 'Braun',
  fullname: 'Nicole Braun',
  email: 'nicole.braun@zammad.org',
  organization: {
    __typename: 'Organization',
    id: 'gid://zammad/Organization/1',
    internalId: 1,
    name: 'Zammad Foundation',
    active: true,
    policy: {
      update: true,
      destroy: true,
    },
    createdAt: '2020-01-01T12:00:00Z',
    updatedAt: '2020-01-01T12:00:00Z',
  },
  phone: '+49 123 4567890',
  mobile: '+49 987 6543210',
  image: null,
  vip: false,
  outOfOffice: false,
  outOfOfficeStartAt: null,
  outOfOfficeEndAt: null,
  hasSecondaryOrganizations: false,
  active: true,
  policy: {
    update: true,
    destroy: true,
  },
  ticketsCount: {
    open: 1,
    openSearchQuery: 'openSearch',
    closed: 0,
    closedSearchQuery: 'closedSearch',
    organizationOpen: 1,
    organizationOpenSearchQuery: 'openSearchOrg',
    organizationClosed: 0,
    organizationClosedSearchQuery: 'closedSearchOrg',
  },
  createdAt: '2020-01-01T12:00:00Z',
  updatedAt: '2020-01-01T12:00:00Z',
}

const mockTicketsByCustomerQueryWithData = (ticketCount: number) => {
  const testTickets = Array(ticketCount).fill(createDummyTicket())

  const edges = testTickets.slice(0, 5).map(
    (node) =>
      ({
        __typename: 'TicketEdge',
        node,
      }) as TicketEdge,
  )

  mockTicketsByCustomerQuery({
    ticketsByCustomer: {
      __typename: 'TicketConnection',
      edges,
      pageInfo: {
        endCursor: null,
      },
      totalCount: testTickets.length,
    },
  })
}

const renderCustomerTicketList = async (ticketCount: number, props?: Partial<Props>) => {
  mockTicketsByCustomerQueryWithData(ticketCount)

  const view = renderComponent(CustomerTicketList, {
    props: {
      customer,
      label: 'Open Tickets',
      stateTypeCategory: EnumTicketStateTypeCategory.Open,
      ...props,
    },
    router: true,
  })

  await vi.dynamicImportSettled()
  await flushPromises()

  return view
}

describe('CustomerTicketList.vue', () => {
  afterEach(async () => {
    await vi.dynamicImportSettled()
    await flushPromises()
  })

  it('render heading with a ticket count', async () => {
    const view = await renderCustomerTicketList(5)

    expect(view.getByRole('heading', { name: 'Open Tickets', level: 3 })).toHaveTextContent('5')
  })

  it('renders a list of tickets', async () => {
    const view = await renderCustomerTicketList(3)

    const list = view.getByRole('list')

    expect(within(list).getAllByRole('listitem')).toHaveLength(3)

    expect(view.queryByRole('button', { name: 'Show more' })).not.toBeInTheDocument()
    expect(view.queryByRole('button', { name: 'Search all' })).not.toBeInTheDocument()
  })

  it('renders a show more button if needed', async () => {
    const view = await renderCustomerTicketList(6)

    const button = view.getByRole('button', { name: 'Show more' })

    await view.events.click(button)

    const calls = await waitForTicketsByCustomerQueryCalls()

    expect(calls.at(-1)?.variables.pageSize).toEqual(100)
  })

  it('renders a search all button', async () => {
    const view = await renderCustomerTicketList(6, {
      stateTypeCategory: EnumTicketStateTypeCategory.Closed,
    })

    const button = view.getByRole('button', { name: 'Search all' })

    await view.events.click(button)

    const router = getTestRouter()

    await waitFor(() => expect(router.currentRoute.value.name).toBe('Search'))

    expect(router.currentRoute.value.params).toEqual({
      searchTerm: 'closedSearch',
    })
  })

  it("supports customer organization's filter", async () => {
    await renderCustomerTicketList(2, {
      customerOrganizations: true,
    })

    const calls = await waitForTicketsByCustomerQueryCalls()

    expect(calls.at(-1)?.variables.customerOrganizations).toBe(true)
  })

  it('refetch list on emitted event', async () => {
    await renderCustomerTicketList(2, {
      customerOrganizations: true,
    })

    const calls = await waitForTicketsByCustomerQueryCalls()

    expect(calls).toHaveLength(1)

    emitter.emit(`customer-ticket-list-refetch:${customer.id}`)

    await waitFor(() => {
      expect(calls).toHaveLength(2)
    })
  })
})
