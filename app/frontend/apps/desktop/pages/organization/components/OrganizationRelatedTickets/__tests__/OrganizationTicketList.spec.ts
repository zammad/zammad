// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'
import { flushPromises } from '@vue/test-utils'

import { renderComponent } from '#tests/support/components/index.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  EnumTicketStateTypeCategory,
  type Organization,
  type TicketEdge,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import emitter from '#shared/utils/emitter.ts'

import {
  mockTicketsByOrganizationQuery,
  waitForTicketsByOrganizationQueryCalls,
} from '#desktop/entities/ticket/graphql/queries/ticketsByOrganization.mocks.ts'

import OrganizationTicketList, { type Props } from '../OrganizationTicketList.vue'

import '#tests/graphql/builders/mocks.ts'

const organization: Organization = {
  __typename: 'Organization',
  id: convertToGraphQLId('Organization', 1),
  internalId: 1,
  name: 'Zammad Foundation',
  shared: true,
  policy: {
    update: true,
    destroy: false,
  },
  ticketsCount: {
    open: 1,
    openSearchQuery: 'openSearch',
    closed: 0,
    closedSearchQuery: 'closedSearch',
  },
  createdAt: '2026-01-01T12:00:00Z',
  updatedAt: '2026-01-01T12:00:00Z',
}

const mockTicketsByOrganization = (ticketCount: number) => {
  const testTickets = Array(ticketCount).fill(createDummyTicket())

  const edges = testTickets.slice(0, 5).map(
    (node) =>
      ({
        __typename: 'TicketEdge',
        node,
      }) as TicketEdge,
  )

  mockTicketsByOrganizationQuery({
    ticketsByOrganization: {
      __typename: 'TicketConnection',
      edges,
      pageInfo: {
        endCursor: null,
      },
      totalCount: testTickets.length,
    },
  })
}

const renderOrganizationTicketList = async (ticketCount: number, props?: Partial<Props>) => {
  mockTicketsByOrganization(ticketCount)

  const view = renderComponent(OrganizationTicketList, {
    props: {
      organization,
      label: 'Open Tickets',
      stateTypeCategory: EnumTicketStateTypeCategory.Open,
      ...props,
    },
    router: true,
  })

  await flushPromises()

  return view
}

describe('OrganizationTicketList.vue', () => {
  afterEach(async () => {
    await flushPromises()
  })

  it('render heading with a ticket count', async () => {
    const view = await renderOrganizationTicketList(5)

    expect(view.getByRole('heading', { name: 'Open Tickets', level: 3 })).toHaveTextContent('5')
  })

  it('renders a list of tickets', async () => {
    const view = await renderOrganizationTicketList(3)

    const list = view.getByRole('list')

    expect(within(list).getAllByRole('listitem')).toHaveLength(3)

    expect(view.queryByRole('button', { name: 'Show more' })).not.toBeInTheDocument()
    expect(view.queryByRole('button', { name: 'Search all' })).not.toBeInTheDocument()
  })

  it('renders a show more button if needed', async () => {
    const view = await renderOrganizationTicketList(6)

    const button = view.getByRole('button', { name: 'Show more' })

    await view.events.click(button)

    const calls = await waitForTicketsByOrganizationQueryCalls()

    expect(calls.at(-1)?.variables.pageSize).toEqual(100)
  })

  it('renders a search all button', async () => {
    const view = await renderOrganizationTicketList(6, {
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

  it('refetch list on emitted event', async () => {
    await renderOrganizationTicketList(2)

    const calls = await waitForTicketsByOrganizationQueryCalls()

    expect(calls).toHaveLength(1)

    emitter.emit(`organization-ticket-list-refetch:${organization.internalId}`)

    waitFor(() => {
      expect(calls).toHaveLength(2)
    })
  })
})
