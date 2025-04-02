// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockDetailSearchQuery,
  waitForDetailSearchQueryCalls,
} from '#desktop/components/Search/graphql/queries/detailSearch.mocks.ts'
import { waitForSearchCountsQueryCalls } from '#desktop/components/Search/graphql/queries/searchCounts.mocks.ts'
import { waitForTicketUpdateBulkMutationCalls } from '#desktop/entities/ticket/graphql/mutations/updateBulk.mocks.ts'

const visitSearchView = async (searchTerm = 'test') => {
  const view = await visitView(`/search/${searchTerm}`)

  const searchContainer = view.getByTestId('search-container')

  return { view, searchContainer }
}

describe('search view', () => {
  it('renders view correctly', async () => {
    mockPermissions(['ticket.agent'])

    const { searchContainer } = await visitSearchView()

    expect(
      within(searchContainer).getByRole('searchbox', { name: 'Search…' }),
    ).toHaveDisplayValue('test')
  })

  it('write quick search input correctly to the search view input', async () => {
    mockPermissions(['ticket.agent'])

    const { searchContainer, view } = await visitSearchView()

    const primaryNavigationSidebar = view.getByRole('complementary', {
      name: 'Main sidebar',
    })

    const quickSearchInput = within(primaryNavigationSidebar).getByRole(
      'searchbox',
    )

    await view.events.type(quickSearchInput, 'fooBar')
    await view.events.keyboard('{Enter}')

    await waitFor(() =>
      expect(
        within(searchContainer).getByRole('searchbox', { name: 'Search…' }),
      ).toHaveDisplayValue('fooBar'),
    )

    const router = getTestRouter()

    await waitFor(() =>
      expect(router.currentRoute.value.fullPath).toBe(
        '/search/fooBar?entity=Ticket',
      ),
    )

    const mocks = await waitForDetailSearchQueryCalls()

    expect(mocks.at(0)?.variables).toEqual({
      limit: 30,
      onlyIn: 'Ticket',
      search: 'test',
    })

    expect(view.getByRole('table')).toBeInTheDocument()
  })

  it('selects a ticket for bulk edit', async () => {
    mockPermissions(['ticket.agent'])

    const ticket = createDummyTicket()

    mockDetailSearchQuery({
      search: {
        totalCount: 1,
        items: [ticket],
      },
    })

    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          group_id: {
            options: [
              {
                value: 2,
                label: 'test group',
              },
            ],
          },
          owner_id: {
            options: [
              {
                value: 3,
                label: 'Test Admin Agent',
              },
            ],
          },
          state_id: {
            options: [
              {
                value: 4,
                label: 'closed',
              },
            ],
          },
          pending_time: {
            show: false,
          },
        },
      },
    })

    const { view } = await visitSearchView()

    expect(
      view.queryByRole('button', { name: 'Bulk Action' }),
    ).not.toBeInTheDocument()

    const mainContent = view.getByRole('main')

    const checkboxes = within(mainContent).getAllByRole('checkbox', {
      name: 'Select this entry',
    })

    await view.events.click(checkboxes[0])

    await view.events.click(
      await view.findByRole('button', { name: 'Bulk Actions' }),
    )

    expect(
      await view.findByRole('complementary', { name: 'Tickets Bulk Edit' }),
    ).toBeInTheDocument()

    const ticketState = await view.findByLabelText('State')

    await view.events.click(ticketState)

    expect(await view.findByRole('menu')).toBeInTheDocument()

    await view.events.click(view.getByRole('option', { name: 'closed' }))

    await view.events.click(view.getByRole('button', { name: 'Apply' }))

    const calls = await waitForTicketUpdateBulkMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      input: {
        article: null,
        stateId: convertToGraphQLId('Ticket::State', 4),
      },
      ticketIds: [ticket.id],
    })
    expect(await waitForDetailSearchQueryCalls()).toHaveLength(2)
    expect(await waitForSearchCountsQueryCalls()).toHaveLength(2)
  })

  it('resets checked tickets on text input', async () => {
    mockPermissions(['ticket.agent'])

    const ticket = createDummyTicket()

    mockDetailSearchQuery({
      search: {
        totalCount: 1,
        items: [ticket],
      },
    })

    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          group_id: {
            options: [
              {
                value: 2,
                label: 'test group',
              },
            ],
          },
          owner_id: {
            options: [
              {
                value: 3,
                label: 'Test Admin Agent',
              },
            ],
          },
          state_id: {
            options: [
              {
                value: 4,
                label: 'closed',
              },
            ],
          },
          pending_time: {
            show: false,
          },
        },
      },
    })
    const { view } = await visitSearchView()

    await waitForDetailSearchQueryCalls()
    await waitForNextTick()

    const mainContent = view.getByRole('main')

    const checkboxes = within(mainContent).getAllByRole('checkbox', {
      name: 'Select this entry',
    })

    expect(
      within(mainContent).queryByRole('checkbox', {
        name: 'Deselect this entry',
      }),
    ).not.toBeInTheDocument()

    await view.events.click(checkboxes[0])

    expect(
      await within(mainContent).findByRole('checkbox', {
        name: 'Deselect this entry',
      }),
    ).toBeInTheDocument()

    await view.events.type(
      within(mainContent).getByRole('searchbox', { name: 'Search…' }),
      'more text',
    )

    await waitFor(() =>
      expect(
        within(mainContent).queryByRole('checkbox', {
          name: 'Deselect this entry',
        }),
      ).not.toBeInTheDocument(),
    )
  })
})
