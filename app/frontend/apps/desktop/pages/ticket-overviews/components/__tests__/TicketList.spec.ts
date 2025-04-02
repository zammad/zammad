// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import ticketObjectAttributes from '#tests/graphql/factories/fixtures/ticket-object-attributes.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'

import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumOrderDirection } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockTicketsCachedByOverviewQuery,
  waitForTicketsCachedByOverviewQueryCalls,
} from '#desktop/entities/ticket/graphql/queries/ticketsCachedByOverview.mocks.ts'
import TicketList from '#desktop/pages/ticket-overviews/components/TicketList.vue'

mockRouterHooks()

vi.hoisted(() => {
  vi.useFakeTimers()
  vi.setSystemTime(new Date('2011-11-11T12:00:00Z'))
})

const applyMocks = (ticket: TicketById = createDummyTicket()) => {
  mockApplicationConfig({
    ui_ticket_overview_ticket_limit: 1000,
  })

  mockTicketsCachedByOverviewQuery({
    ticketsCachedByOverview: {
      edges: [{ node: { ...ticket } }],
      pageInfo: {
        endCursor: 'MjU',
        hasNextPage: true,
      },
      totalCount: 1,
    },
  })

  mockObjectManagerFrontendAttributesQuery({
    objectManagerFrontendAttributes: ticketObjectAttributes(),
  })
}

const renderTicketList = (props: { groupBy?: string } = {}) => {
  const headers = {
    title: 'Title',
    organization: 'Organization',
    group: 'Group',
    owner: 'Owner',
    state: 'State',
    created_at: 'Created at',
  }

  const wrapper = renderComponent(TicketList, {
    props: {
      overviewId: convertToGraphQLId('Overview', 1),
      headers: Object.keys(headers),
      orderBy: 'group',
      orderDirection: 'ASCENDING',
      overviewName: 'test tickets',
      ...props,
    },
    router: true,
    form: true,
  })
  return { wrapper, headers }
}
describe('TicketList', () => {
  afterAll(() => {
    vi.resetAllMocks()
  })

  describe('loading states', () => {
    it('displays the skeleton for the table on initial load', async () => {
      mockTicketsCachedByOverviewQuery({
        ticketsCachedByOverview: {
          edges: [{ node: createDummyTicket() }],
          pageInfo: {
            endCursor: 'MjU',
            hasNextPage: true,
          },
          totalCount: 207,
        },
      })

      const wrapper = renderComponent(TicketList, {
        props: {
          overviewId: convertToGraphQLId('Overview', 1),
          overviewName: 'test tickets',
          headers: [
            'title',
            'customer',
            'group',
            'owner',
            'state',
            'created_at',
          ],
          orderBy: 'group',
          orderDirection: 'ASCENDING',
        },
        router: true,
        form: true,
      })

      console.log(wrapper.html())

      expect(await wrapper.findByTestId('table-skeleton')).toBeInTheDocument()
    })
  })

  it('displays a table overview with tickets', async () => {
    vi.useRealTimers()

    const ticket = createDummyTicket()

    applyMocks(ticket)

    const { wrapper, headers } = renderTicketList()

    const table = await wrapper.findByRole('table', {
      name: 'Overview: test tickets',
    })

    await Promise.all(
      Object.values(headers).map(async (header) => {
        expect(
          await within(table).findByRole('columnheader', { name: header }),
        ).toBeInTheDocument()
      }),
    )

    expect(
      wrapper.getByRole('cell', { name: ticket.title }),
    ).toBeInTheDocument()

    expect(
      wrapper.getByRole('cell', { name: ticket.group.name! }),
    ).toBeInTheDocument()

    expect(
      wrapper.getByRole('cell', { name: ticket.state.name }),
    ).toBeInTheDocument()
  })

  it('shows priority icon if flag is set', async () => {
    mockApplicationConfig({
      ui_ticket_priority_icons: true,
    })

    const ticket = createDummyTicket({
      defaultPriority: {
        id: convertToGraphQLId('Ticket::Priority', 3),
        defaultCreate: true,
        name: '3 high',
        uiColor: 'high-priority',
      },
    })
    applyMocks(ticket)

    const { wrapper } = renderTicketList()

    expect(await wrapper.findByIconName('priority-high')).toBeInTheDocument()
  })

  it('resizes table column', async () => {
    await applyMocks()

    const { wrapper, headers } = renderTicketList()

    const resizeButtons = await wrapper.findAllByRole('button', {
      name: 'Resize column',
    })

    expect(resizeButtons).toHaveLength(Object.keys(headers).length - 1) // last one does not have a resize button

    const tableHeaders = await wrapper.findAllByRole('columnheader')

    const firstResizeButton = resizeButtons[0]
    const firstTableHeader = tableHeaders[0]

    expect(firstTableHeader).toHaveStyle({ width: '25px' })

    firstResizeButton.focus()
    // Does not work in test environment
    // await wrapper.events.keyboard('{ArrowRight}')
    // await waitFor(() => expect(firstTableHeader).toHaveStyle({ width: '30px' }))
  })

  it('sorts table column', async () => {
    await applyMocks()

    const { wrapper } = renderTicketList()

    const sortButtons = await wrapper.findAllByRole('button', {
      name: 'Sorted ascending',
    })

    const firstSortButton = sortButtons[0]

    await wrapper.events.click(firstSortButton)

    const mock = await waitForTicketsCachedByOverviewQueryCalls()

    expect(mock.at(-1)?.variables).toEqual({
      cacheTtl: 5,
      knownCollectionSignature: undefined,
      orderBy: 'created_at',
      orderDirection: EnumOrderDirection.Ascending,
      overviewId: convertToGraphQLId('Overview', 1),
      pageSize: 30,
      renewCache: false,
    })
  })

  it.todo('allows grouping of rows', async () => {
    const ticket = createDummyTicket()

    applyMocks(ticket)

    const { wrapper } = renderTicketList({ groupBy: 'customer' })

    expect(
      await wrapper.findByRole('cell', { name: ticket.customer.fullname! }),
    ).toBeInTheDocument()
  })
})
