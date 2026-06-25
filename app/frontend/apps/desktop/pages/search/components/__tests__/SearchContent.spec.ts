// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within, waitFor } from '@testing-library/vue'
import { computed } from 'vue'

import ticketObjectAttributes from '#tests/graphql/factories/fixtures/ticket-object-attributes.ts'
import { getByIconName } from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'
import { EnumSearchableModels, EnumTicketStateColorCode } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockDetailSearchQuery,
  waitForDetailSearchQueryCalls,
} from '#desktop/components/Search/graphql/queries/detailSearch.mocks.ts'
import {
  mockSearchCountsQuery,
  waitForSearchCountsQueryCalls,
} from '#desktop/components/Search/graphql/queries/searchCounts.mocks.ts'
import { CURRENT_TASKBAR_TAB_KEY } from '#desktop/entities/user/current/composables/useTaskbarTab.ts'
import SearchContent from '#desktop/pages/search/components/SearchContent.vue'

mockRouterHooks()

const renderSearchContent = (props?: { searchTerm?: string }) => {
  mockObjectManagerFrontendAttributesQuery({
    objectManagerFrontendAttributes: ticketObjectAttributes(),
  })

  return renderComponent(SearchContent, {
    props,
    router: true,
    form: true,
    provide: [
      [
        CURRENT_TASKBAR_TAB_KEY,
        {
          currentTaskbarTab: computed(() => undefined),
          currentTaskbarTabId: computed(() => undefined),
        },
      ],
    ],
  })
}

const mockTicketSearchResult = (totalCount: number, items: any[]) => {
  mockDetailSearchQuery({
    search: { totalCount, items },
  })
}

const createSampleTicket = (id: number, title: string, number = 121) => ({
  id: convertToGraphQLId('Ticket', id),
  internalId: id,
  title,
  number,
  customer: {
    id: convertToGraphQLId('User', 2),
    fullname: 'Nicole Braun User',
  },
  group: {
    id: convertToGraphQLId('Group', 6),
    name: 'Group 1',
  },
  state: {
    id: convertToGraphQLId('State', 2),
    name: 'open',
  },
  stateColorCode: EnumTicketStateColorCode.Open,
  priority: {
    id: convertToGraphQLId('TicketPriority', 2),
    name: '2 normal',
    uiColor: null,
  },
  createdAt: '2025-02-20T10:21:14Z',
  __typename: 'Ticket',
})

describe('SearchContent', () => {
  beforeEach(async () => {
    mockPermissions(['ticket.agent'])
    // The router is a module-level singleton and persists state across tests
    // — reset the URL so a previous test's filter / search query doesn't leak.
    // The router is undefined until the first renderComponent call has run.
    const router = getTestRouter()
    if (router) await router.push('/')
  })

  it('displays breadcrumbs', async () => {
    mockTicketSearchResult(1, [createSampleTicket(469, 'Foo ticket title')])

    const wrapper = renderSearchContent({ searchTerm: '123' })

    const breadcrumbs = wrapper.getByRole('navigation', {
      name: 'Breadcrumb navigation',
    })

    expect(
      within(breadcrumbs).getByRole('heading', { name: 'Results', level: 1 }),
    ).toBeInTheDocument()
    expect(within(breadcrumbs).getByText('Search')).toBeInTheDocument()

    await waitFor(() => expect(breadcrumbs).toHaveTextContent('SearchResults1'))
  })

  it('displays ticket search results', async () => {
    mockTicketSearchResult(1, [createSampleTicket(469, 'Foo ticket title', 12469)])

    const wrapper = renderSearchContent({ searchTerm: 'Foo ticket title' })

    const table = await wrapper.findByRole('table', {
      name: 'Search result for: Ticket',
    })

    // Ticket state `open` indicator.
    expect(getByIconName(table, 'check-circle-no')).toBeInTheDocument()

    await waitFor(() =>
      expect(within(table).getByRole('link', { name: '12469' })).toBeInTheDocument(),
    )
  })

  it('keeps the previous results visible while a new search term loads', async () => {
    // Regression (#1290): changing the search term must not blank the list.
    // The previous result stays rendered until the next response arrives, so
    // the list never flashes empty (a skeleton/empty frame) in between.
    mockTicketSearchResult(1, [createSampleTicket(469, 'Ticket A')])

    const wrapper = renderSearchContent({ searchTerm: 'aaa' })

    expect(await wrapper.findByText('Ticket A')).toBeInTheDocument()

    // The next search term resolves to a different result.
    mockTicketSearchResult(1, [createSampleTicket(470, 'Ticket B')])

    await wrapper.rerender({ searchTerm: 'bbb' })

    // While the new query is in flight, the previous result must remain visible.
    expect(wrapper.getByText('Ticket A')).toBeInTheDocument()

    // Once the new response resolves it replaces the previous result.
    expect(await wrapper.findByText('Ticket B')).toBeInTheDocument()
    expect(wrapper.queryByText('Ticket A')).not.toBeInTheDocument()
  })

  it('supports optional ticket priority column', async () => {
    mockApplicationConfig({
      ui_ticket_priority_icons: true,
    })

    mockTicketSearchResult(1, [createSampleTicket(469, 'Foo ticket title', 12469)])

    const wrapper = renderSearchContent({ searchTerm: 'Foo ticket title' })

    const table = await wrapper.findByRole('table', {
      name: 'Search result for: Ticket',
    })

    expect(getByIconName(table, 'priority-normal-micro-2')).toBeInTheDocument()
  })

  it('syncs search input with URL param', async () => {
    mockTicketSearchResult(1, [createSampleTicket(469, 'Foo ticket title', 12469)])

    const wrapper = renderSearchContent({ searchTerm: 'foo-bar' })

    await waitFor(() => expect(wrapper.getByRole('searchbox')).toHaveDisplayValue('foo-bar'))
  })

  it('displays result counts', async () => {
    mockTicketSearchResult(2, [
      createSampleTicket(469, 'Ticket A'),
      createSampleTicket(470, 'Ticket B'),
    ])

    const wrapper = renderSearchContent({ searchTerm: 'ticket' })

    await waitFor(() => expect(wrapper.getAllByText('2')).toHaveLength(2))
  })

  it('shows default empty message when no results', async () => {
    mockTicketSearchResult(0, [])

    const wrapper = renderSearchContent({ searchTerm: 'qux' })

    expect(await wrapper.findByText('No search results for this query.')).toBeInTheDocument()
  })

  it('resets to the idle search state when the search term is cleared', async () => {
    mockTicketSearchResult(1, [createSampleTicket(469, 'Foo ticket title', 12469)])

    const wrapper = renderSearchContent({ searchTerm: 'ticket' })

    const callsForDetailSearchQuery = waitForDetailSearchQueryCalls()
    const callsForCountsQuery = waitForSearchCountsQueryCalls()

    await wrapper.findByRole('table', {
      name: 'Search result for: Ticket',
    })

    await wrapper.rerender({ searchTerm: '' })

    await waitFor(() =>
      expect(
        wrapper.getByText('Start typing or apply filters to get the search results.'),
      ).toBeInTheDocument(),
    )

    expect(wrapper.queryByText('No search results for this query.')).not.toBeInTheDocument()

    // Queries should not be called anymore when resetting to idle state.
    expect((await callsForDetailSearchQuery).length).toBe(1)
    expect((await callsForCountsQuery).length).toBe(1)

    await wrapper.rerender({ searchTerm: 'new ticket search' })

    await waitForDetailSearchQueryCalls()
    await waitForSearchCountsQueryCalls()

    expect((await callsForDetailSearchQuery).length).toBe(2)
    expect((await callsForCountsQuery).length).toBe(2)
  })

  it('displays entity counts for agent', async () => {
    mockTicketSearchResult(0, [])
    mockSearchCountsQuery({
      searchCounts: [
        { model: EnumSearchableModels.Organization, totalCount: 100 },
        { model: EnumSearchableModels.User, totalCount: 250 },
      ],
    })

    const wrapper = renderSearchContent({ searchTerm: '123' })

    await Promise.all([waitForSearchCountsQueryCalls(), waitForDetailSearchQueryCalls()])

    expect(wrapper.getByRole('tab', { name: 'Organization' })).toHaveTextContent('100')
    expect(wrapper.getByRole('tab', { name: 'User' })).toHaveTextContent('250')
    expect(wrapper.getByRole('tab', { name: 'Ticket' })).toHaveTextContent('0')
  })

  it('uses the real total count for the visible entity tab, not the loaded page size', async () => {
    // The detail search returns the total match count alongside a single
    // page of items. The tab badge has to follow totalCount, otherwise it
    // would shrink/grow with pagination.
    mockTicketSearchResult(100, [createSampleTicket(469, 'Foo ticket title')])

    const wrapper = renderSearchContent({ searchTerm: 'ticket' })

    await waitForDetailSearchQueryCalls()

    await waitFor(() =>
      expect(wrapper.getByRole('tab', { name: 'Ticket' })).toHaveTextContent('100'),
    )
  })

  it('shows a dash on every entity tab in the idle state', async () => {
    // No search term, no filter anywhere — neither query should fire and
    // every tab should display the dash placeholder, not a stale number.
    const wrapper = renderSearchContent()

    await wrapper.findByRole('tab', { name: 'Ticket' })

    expect(wrapper.getByRole('tab', { name: 'Ticket' })).toHaveTextContent('-')
    expect(wrapper.getByRole('tab', { name: 'User' })).toHaveTextContent('-')
    expect(wrapper.getByRole('tab', { name: 'Organization' })).toHaveTextContent('-')
  })

  it('drops entity tab counts when the search term is cleared', async () => {
    mockTicketSearchResult(2, [
      createSampleTicket(469, 'Ticket A'),
      createSampleTicket(470, 'Ticket B'),
    ])
    mockSearchCountsQuery({
      searchCounts: [
        { model: EnumSearchableModels.Organization, totalCount: 100 },
        { model: EnumSearchableModels.User, totalCount: 250 },
      ],
    })

    const wrapper = renderSearchContent({ searchTerm: 'ticket' })

    await Promise.all([waitForSearchCountsQueryCalls(), waitForDetailSearchQueryCalls()])

    await waitFor(() =>
      expect(wrapper.getByRole('tab', { name: 'Organization' })).toHaveTextContent('100'),
    )
    expect(wrapper.getByRole('tab', { name: 'User' })).toHaveTextContent('250')
    expect(wrapper.getByRole('tab', { name: 'Ticket' })).toHaveTextContent('2')

    await wrapper.rerender({ searchTerm: '' })

    await waitFor(() => {
      expect(wrapper.getByRole('tab', { name: 'Organization' })).not.toHaveTextContent('100')
      expect(wrapper.getByRole('tab', { name: 'User' })).not.toHaveTextContent('250')
      expect(wrapper.getByRole('tab', { name: 'Ticket' })).not.toHaveTextContent('2')
    })
  })

  it('allows sorting of search results', async () => {
    mockTicketSearchResult(1, [createSampleTicket(469, 'Foo ticket title')])

    const wrapper = renderSearchContent({ searchTerm: 'Foo ticket title' })

    await waitForDetailSearchQueryCalls()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Sort by Title ascending' }))
    const mocks = await waitForDetailSearchQueryCalls()

    expect(mocks[1].variables.orderDirection).toBe('ASCENDING')
  })

  it('only displays tickets for customer role', async () => {
    mockPermissions(['ticket.customer'])
    mockTicketSearchResult(1, [createSampleTicket(469, 'Customer Ticket')])

    const wrapper = renderSearchContent({ searchTerm: 'Customer Ticket' })

    await waitFor(() => expect(wrapper.getByText('Customer Ticket')).toBeInTheDocument())
  })

  it('only displays Action Button for ticket entity', async () => {
    mockPermissions(['ticket.agent'])

    mockTicketSearchResult(2, [
      createSampleTicket(469, 'Ticket A'),
      createSampleTicket(470, 'Ticket B'),
    ])

    mockSearchCountsQuery({
      searchCounts: [
        { model: EnumSearchableModels.Organization, totalCount: 100 },
        { model: EnumSearchableModels.User, totalCount: 100 },
      ],
    })
    const wrapper = renderSearchContent({ searchTerm: 'ticket' })

    await waitForDetailSearchQueryCalls()
    await waitForNextTick()

    const checkboxes = wrapper.getAllByRole('checkbox', {
      name: 'Select this entry',
    })

    await wrapper.events.click(checkboxes[0])

    expect(wrapper.getByRole('button', { name: 'Bulk actions' })).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByRole('tab', { name: 'Organization' }))

    expect(wrapper.queryByRole('button', { name: 'Bulk actions' })).not.toBeInTheDocument()

    await wrapper.events.click(wrapper.getByRole('tab', { name: 'User' }))

    expect(wrapper.queryByRole('button', { name: 'Bulk actions' })).not.toBeInTheDocument()
  })
})
