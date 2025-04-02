// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { within, waitFor } from '@testing-library/vue'
import { computed } from 'vue'

import ticketObjectAttributes from '#tests/graphql/factories/fixtures/ticket-object-attributes.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'
import {
  EnumSearchableModels,
  EnumTicketStateColorCode,
} from '#shared/graphql/types.ts'
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
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
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
    mockTicketSearchResult(1, [
      createSampleTicket(469, 'Foo ticket title', 12469),
    ])

    const wrapper = renderSearchContent({ searchTerm: 'Foo ticket title' })

    const table = await wrapper.findByRole('table', {
      name: 'Search result for: Ticket',
    })
    expect(
      within(table).getByRole('link', { name: '12469' }),
    ).toBeInTheDocument()
  })

  it('syncs search input with URL param', async () => {
    const wrapper = renderSearchContent({ searchTerm: 'foo-bar' })

    await waitFor(() =>
      expect(wrapper.getByRole('searchbox')).toHaveDisplayValue('foo-bar'),
    )
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

    expect(
      await wrapper.findByText('No search results for this query.'),
    ).toBeInTheDocument()
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

    await Promise.all([
      waitForSearchCountsQueryCalls(),
      waitForDetailSearchQueryCalls(),
    ])

    expect(
      wrapper.getByRole('tab', { name: 'Organization 100' }),
    ).toBeInTheDocument()
    expect(wrapper.getByRole('tab', { name: 'User 250' })).toBeInTheDocument()
    expect(wrapper.getByRole('tab', { name: 'Ticket 0' })).toBeInTheDocument()
  })

  it('allows sorting of search results', async () => {
    mockTicketSearchResult(1, [createSampleTicket(469, 'Foo ticket title')])

    const wrapper = renderSearchContent({ searchTerm: 'Foo ticket title' })

    await waitForDetailSearchQueryCalls()

    await wrapper.events.click(
      wrapper.getAllByRole('button', { name: 'Sorted descending' })[0],
    )
    const mocks = await waitForDetailSearchQueryCalls()

    expect(mocks[1].variables.orderDirection).toBe('ASCENDING')
  })

  it('clears search input when reset button is clicked', async () => {
    mockTicketSearchResult(0, [])
    const wrapper = renderSearchContent({ searchTerm: 'Foo ticket title' })

    await waitForDetailSearchQueryCalls()
    await waitForNextTick()

    const panel = wrapper.getByTestId('tab-panel-Ticket')

    await wrapper.events.click(
      await within(panel).findByRole('button', { name: 'Clear search' }),
    )

    // FIXME: Does not work without this, possibly due to missing route and push on cleared search.
    wrapper.rerender({ searchTerm: '' })

    await waitForNextTick()

    const searchField = wrapper.getByRole('searchbox', { name: 'Search…' })

    await waitFor(() =>
      expect(
        within(panel).queryByRole('button', { name: 'Clear search' }),
      ).not.toBeInTheDocument(),
    )

    expect(searchField).toHaveDisplayValue('')
    expect(searchField).toHaveFocus()
  })

  it('only displays tickets for customer role', async () => {
    mockPermissions(['ticket.customer'])
    mockTicketSearchResult(1, [createSampleTicket(469, 'Customer Ticket')])

    const wrapper = renderSearchContent({ searchTerm: 'Customer Ticket' })

    await waitFor(() =>
      expect(wrapper.getByText('Customer Ticket')).toBeInTheDocument(),
    )
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

    expect(
      wrapper.getByRole('button', { name: 'Bulk Actions' }),
    ).toBeInTheDocument()

    await wrapper.events.click(
      wrapper.getByRole('tab', { name: 'Organization 100' }),
    )

    expect(
      wrapper.queryByRole('button', { name: 'Bulk Actions' }),
    ).not.toBeInTheDocument()

    await wrapper.events.click(wrapper.getByRole('tab', { name: 'User 100' }))

    expect(
      wrapper.queryByRole('button', { name: 'Bulk Actions' }),
    ).not.toBeInTheDocument()
  })
})
