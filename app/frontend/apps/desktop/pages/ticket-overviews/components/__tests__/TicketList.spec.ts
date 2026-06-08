// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { computed, nextTick } from 'vue'

import ticketObjectAttributes from '#tests/graphql/factories/fixtures/ticket-object-attributes.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'

import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumOrderDirection } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import { waitForTicketsCachedByOverviewQueryCalls } from '#desktop/entities/ticket/graphql/queries/ticketsCachedByOverview.mocks.ts'
import TicketList from '#desktop/pages/ticket-overviews/components/TicketList.vue'

import { mockDefaultTicketsCachedByOverview } from '../../__tests__/mocks/ticket-overviews-mocks.ts'

mockRouterHooks()

vi.hoisted(() => {
  vi.useFakeTimers()
  vi.setSystemTime(new Date('2011-11-11T12:00:00Z'))
})

const applyMocks = (ticket: TicketById = createDummyTicket()) => {
  mockDefaultTicketsCachedByOverview({
    edges: [{ node: ticket }],
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
    afterEach(() => {
      vi.useRealTimers()
      vi.resetAllMocks()
    })

    it('displays the skeleton for the table on initial load', async () => {
      vi.useFakeTimers()
      mockDefaultTicketsCachedByOverview({ totalCount: 207 })

      // mock to show a endless loading to make sure indicator is shown
      // Otherwise the timing won't work.
      vi.spyOn(QueryHandler.prototype, 'loadingWithoutCachedResult').mockReturnValue(
        computed(() => true),
      )

      const wrapper = renderComponent(TicketList, {
        props: {
          overviewId: convertToGraphQLId('Overview', 1),
          overviewName: 'test tickets',
          headers: ['title', 'customer', 'group', 'owner', 'state', 'created_at'],
          orderBy: 'group',
          orderDirection: 'ASCENDING',
        },
        router: true,
        form: true,
      })

      // Allow Vue's reactivity and async composables to initialize before
      // advancing fake timers. nextTick uses Promise.resolve() and works
      // correctly with fake timers, unlike flushPromises() which relies on
      // setImmediate (faked by vi.useFakeTimers()).
      await nextTick()

      // Advance timers to trigger the debounced loading state
      await vi.advanceTimersByTimeAsync(0)

      expect(wrapper.getAllByLabelText('Content loader').length).toBeGreaterThan(0)
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
        expect(await within(table).findByRole('columnheader', { name: header })).toBeInTheDocument()
      }),
    )

    expect(wrapper.getByRole('cell', { name: ticket.title })).toBeInTheDocument()

    expect(wrapper.getByRole('cell', { name: ticket.group.name! })).toBeInTheDocument()

    expect(wrapper.getAllByRole('cell', { name: ticket.state.name })).toHaveLength(2) // state is shown as text and as color indicator
  })

  it('exposes a tooltip with the full title on the title cell', async () => {
    vi.useRealTimers()

    const ticket = createDummyTicket({ title: 'A rather long ticket title' })

    applyMocks(ticket)

    const { wrapper } = renderTicketList()

    const titleCell = await wrapper.findByRole('cell', { name: ticket.title })
    const titleLink = within(titleCell).getByRole('link')

    expect(titleLink).toHaveAttribute('data-tooltip', 'true')
    expect(titleLink).toHaveAttribute('aria-label', ticket.title)
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

    expect(await wrapper.findByIconName('priority-high-micro-2')).toBeInTheDocument()
  })

  it('resizes table column', async () => {
    applyMocks()

    const { wrapper, headers } = renderTicketList()

    const resizeButtons = await wrapper.findAllByRole('button', {
      name: 'Resize column',
    })

    expect(resizeButtons).toHaveLength(Object.keys(headers).length - 1) // last one does not have a resize button

    const tableHeaders = await wrapper.findAllByRole('columnheader')

    const firstResizeButton = resizeButtons[0]
    const firstTableHeader = tableHeaders[0]

    expect(firstTableHeader).toHaveStyle({ width: '21px' })

    firstResizeButton.focus()
    // Does not work in test environment
    // await wrapper.events.keyboard('{ArrowRight}')
    // await waitFor(() => expect(firstTableHeader).toHaveStyle({ width: '30px' }))
  })

  it('sorts table column', async () => {
    applyMocks()

    const { wrapper } = renderTicketList()

    const sortButton = await wrapper.findByRole('button', {
      name: 'Sort by Title ascending',
    })

    await wrapper.events.click(sortButton)

    const mock = await waitForTicketsCachedByOverviewQueryCalls()

    expect(mock.at(-1)?.variables).toEqual({
      cacheTtl: 5,
      knownCollectionSignature: undefined,
      orderBy: 'title',
      orderDirection: EnumOrderDirection.Ascending,
      overviewId: convertToGraphQLId('Overview', 1),
      pageSize: 30,
      renewCache: false,
    })
  })

  it('allows grouping of rows', async () => {
    const ticket = createDummyTicket()

    await applyMocks(ticket)

    const { wrapper, headers } = renderTicketList({ groupBy: 'customer' })

    const table = await wrapper.findByRole('table', {
      name: 'Overview: test tickets',
    })

    await Promise.all(
      Object.values(headers).map(async (header) => {
        expect(await within(table).findByRole('columnheader', { name: header })).toBeInTheDocument()
      }),
    )

    expect(wrapper.getByRole('cell', { name: ticket.title })).toBeInTheDocument()

    // Group name with count
    expect(wrapper.getByRole('row', { name: `${ticket.customer.fullname!}1` })).toBeInTheDocument()
  })
})
