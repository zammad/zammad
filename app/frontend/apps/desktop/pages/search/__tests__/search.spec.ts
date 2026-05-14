// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'

import ticketObjectAttributes from '#tests/graphql/factories/fixtures/ticket-object-attributes.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumSearchableModels, type Ticket } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockDetailSearchQuery,
  waitForDetailSearchQueryCalls,
} from '#desktop/components/Search/graphql/queries/detailSearch.mocks.ts'
import { waitForSearchCountsQueryCalls } from '#desktop/components/Search/graphql/queries/searchCounts.mocks.ts'
import {
  mockTicketUpdateBulkMutation,
  waitForTicketUpdateBulkMutationCalls,
} from '#desktop/entities/ticket/graphql/mutations/updateBulk.mocks.ts'

const visitSearchView = async (searchTerm = 'test') => {
  const view = await visitView(`/search/${searchTerm}`)

  const searchContainer = view.getByTestId('search-container')

  return { view, searchContainer }
}

const visitSearchViewWithTicketTitleFilter = async (value: string) => {
  const encodedValue = encodeURIComponent(value)

  return visitView(
    `/search/test?entity=Ticket&filter.0.name=ticket.title&filter.0.operator=matches&filter.0.value=${encodedValue}`,
  )
}

const visitSearchViewWithTicketTitleFilterAndNoSearchTerm = async (value: string) => {
  const encodedValue = encodeURIComponent(value)

  return visitView(
    `/search?entity=Ticket&filter.0.name=ticket.title&filter.0.operator=matches&filter.0.value=${encodedValue}`,
  )
}

let ticket: Ticket

describe('search view', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])

    ticket = createDummyTicket()

    mockDetailSearchQuery({
      search: {
        totalCount: 1,
        items: [ticket],
      },
    })
  })

  it('renders view correctly', async () => {
    const { searchContainer, view } = await visitSearchView()

    expect(within(searchContainer).getByRole('searchbox', { name: 'Search…' })).toHaveDisplayValue(
      'test',
    )

    expect(view.getByRole('tablist', { name: 'Search entity' })).toBeInTheDocument()
    expect(view.getByRole('tablist', { name: 'Search entity' })).toBeInTheDocument()
  })

  it('write quick search input correctly to the search view input', async () => {
    const { searchContainer, view } = await visitSearchView()

    const primaryNavigationSidebar = view.getByRole('complementary', {
      name: 'Main sidebar',
    })

    const quickSearchInput = within(primaryNavigationSidebar).getByRole('searchbox')

    await view.events.type(quickSearchInput, 'fooBar')
    await view.events.keyboard('{Enter}')

    await waitFor(() =>
      expect(
        within(searchContainer).getByRole('searchbox', { name: 'Search…' }),
      ).toHaveDisplayValue('fooBar'),
    )

    const router = getTestRouter()

    await waitFor(() =>
      expect(router.currentRoute.value.fullPath).toBe('/search/fooBar?entity=Ticket'),
    )

    const mocks = await waitForDetailSearchQueryCalls()

    expect(mocks.at(0)?.variables).toEqual({
      filter: null,
      limit: 30,
      onlyIn: 'Ticket',
      search: 'test',
    })

    expect(view.getByRole('table')).toBeInTheDocument()
  })

  it('selects a ticket for bulk edit', async () => {
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

    expect(view.queryByRole('button', { name: 'Bulk actions' })).not.toBeInTheDocument()

    const mainContent = view.getByRole('main')

    const checkboxes = within(mainContent).getAllByRole('checkbox', {
      name: 'Select this entry',
    })

    await view.events.click(checkboxes[0])

    await view.events.click(await view.findByRole('button', { name: 'Bulk actions' }))

    expect(
      await view.findByRole('complementary', { name: 'Tickets bulk edit' }),
    ).toBeInTheDocument()

    const ticketState = await view.findByLabelText('State')

    await view.events.click(ticketState)

    expect(await view.findByRole('menu')).toBeInTheDocument()

    await view.events.click(view.getByRole('option', { name: 'closed' }))

    mockTicketUpdateBulkMutation({
      ticketUpdateBulk: {
        async: false,
        total: 1,
        failedCount: 0,
        inaccessibleTicketIds: [],
        invalidTicketIds: [],
      },
    })

    await view.events.click(view.getByRole('button', { name: 'Apply' }))

    const calls = await waitForTicketUpdateBulkMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      perform: {
        input: {
          article: null,
          stateId: convertToGraphQLId('Ticket::State', 4),
        },
      },
      selector: {
        entityIds: [ticket.id],
      },
    })

    expect(await waitForDetailSearchQueryCalls()).toHaveLength(2)
    expect(await waitForSearchCountsQueryCalls()).toHaveLength(2)
  })

  it('resets checked tickets on text input', async () => {
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

  describe('advanced search filters', () => {
    it('switches entity tab and updates URL entity query param', async () => {
      const { view } = await visitSearchView()

      await waitForDetailSearchQueryCalls()
      await waitForNextTick()

      await view.events.click(view.getByRole('tab', { name: 'Organization' }))

      const router = getTestRouter()

      await waitFor(() =>
        expect(router.currentRoute.value.query.entity).toBe(EnumSearchableModels.Organization),
      )
    })

    describe('client-side filtering', () => {
      beforeEach(() => {
        mockObjectManagerFrontendAttributesQuery({
          objectManagerFrontendAttributes: ticketObjectAttributes(),
        })
      })

      it('applies indexed filter query params to detail search query variables', async () => {
        mockDetailSearchQuery({
          search: {
            totalCount: 2,
            items: [
              {
                ...ticket,
                id: convertToGraphQLId('Ticket', 10),
                internalId: 10,
                title: 'Alpha ticket',
              },
              {
                ...ticket,
                id: convertToGraphQLId('Ticket', 20),
                internalId: 20,
                title: 'Beta ticket',
              },
            ],
          },
        })

        await visitSearchViewWithTicketTitleFilter('Alpha')

        const calls = await waitForDetailSearchQueryCalls()

        expect(calls[0].variables.filter).toEqual({
          operator: 'AND',
          conditions: [
            {
              name: 'ticket.title',
              operator: 'matches',
              value: 'Alpha',
            },
          ],
        })
      })

      it('shows filter count badge when a filter query param is active', async () => {
        const view = await visitSearchViewWithTicketTitleFilter('test')

        const searchContainer = view.getByTestId('search-container')

        await waitForDetailSearchQueryCalls()
        await waitForNextTick()

        await waitFor(() =>
          expect(
            within(searchContainer).getByRole('button', { name: '1 filter(s)' }),
          ).toBeInTheDocument(),
        )
      })

      it('only reports a count for the visible entity when a filter is set on it', async () => {
        mockDetailSearchQuery({
          search: {
            totalCount: 7,
            items: [ticket],
          },
        })

        const view = await visitSearchViewWithTicketTitleFilterAndNoSearchTerm('foo')

        await waitForDetailSearchQueryCalls()
        await waitForNextTick()

        expect(view.getByRole('tab', { name: 'Ticket' })).toHaveTextContent('7')
        expect(view.getByRole('tab', { name: 'User' })).toHaveTextContent('-')
        expect(view.getByRole('tab', { name: 'Organization' })).toHaveTextContent('-')
      })

      it('applies clears filters from route when badge button "clear all filters" is clicked', async () => {
        mockDetailSearchQuery({
          search: {
            totalCount: 1,
            items: [ticket],
          },
        })
        const view = await visitSearchViewWithTicketTitleFilter('test')

        const searchContainer = view.getByTestId('search-container')

        await waitForDetailSearchQueryCalls()
        await waitForNextTick()

        const router = getTestRouter()

        await waitFor(() => {
          expect(
            within(searchContainer).getByRole('button', { name: 'Clear all filters' }),
          ).toBeInTheDocument()
          expect(router.currentRoute.value.query.entity).toBe(EnumSearchableModels.Ticket)
          expect(router.currentRoute.value.query).toHaveProperty('filter.0.name')
          expect(router.currentRoute.value.query).toHaveProperty('filter.0.operator')
          expect(router.currentRoute.value.query).toHaveProperty('filter.0.value')
        })

        const badgeClearButton = within(searchContainer).getByRole('button', {
          name: 'Clear all filters',
        })

        await view.events.click(badgeClearButton) // clears filters from router query params
        await waitForNextTick()

        await waitFor(() => {
          expect(view.queryByRole('button', { name: 'Clear all' })).toBeInTheDocument()
        })

        const confirmationButton = view.getByRole('button', { name: 'Clear all' })
        await view.events.click(confirmationButton) // clears filters from router query params

        await waitFor(() => {
          expect(router.currentRoute.value.query.entity).toBe(EnumSearchableModels.Ticket)
          expect(router.currentRoute.value.query).not.toHaveProperty('filter.0.name')
          expect(router.currentRoute.value.query).not.toHaveProperty('filter.0.operator')
          expect(router.currentRoute.value.query).not.toHaveProperty('filter.0.value')
        })
      })

      it('prompts for confirmation before closing search tab when some client side filtering is configured', async () => {
        mockDetailSearchQuery({
          search: {
            totalCount: 1,
            items: [ticket],
          },
        })
        const view = await visitSearchViewWithTicketTitleFilter('test')

        await waitForDetailSearchQueryCalls()
        await waitForNextTick()

        const primaryNavigationSidebar = view.getByRole('complementary', {
          name: 'Main sidebar',
        })
        const closeSearchTab = within(primaryNavigationSidebar).getByRole('button', {
          name: 'Close this tab',
        })
        await view.events.click(closeSearchTab)

        await waitFor(() => {
          expect(view.queryByRole('button', { name: 'Discard changes' })).toBeInTheDocument()
        })

        const confirmationButton = view.getByRole('button', { name: 'Discard changes' })
        await view.events.click(confirmationButton) // closes tab

        await waitFor(() => {
          expect(
            within(primaryNavigationSidebar).queryByRole('button', {
              name: 'Close this tab',
            }),
          ).not.toBeInTheDocument()
        })
      })

      it('prompts for confirmation, but cancels, before closing search tab when some client side filtering is configured', async () => {
        mockDetailSearchQuery({
          search: {
            totalCount: 1,
            items: [ticket],
          },
        })
        const view = await visitSearchViewWithTicketTitleFilter('test')

        await waitForDetailSearchQueryCalls()
        await waitForNextTick()

        const router = getTestRouter()

        // Confirm route is using client side filtering
        expect(router.currentRoute.value.query.entity).toBe(EnumSearchableModels.Ticket)
        expect(router.currentRoute.value.query).toHaveProperty('filter.0.name')
        expect(router.currentRoute.value.query).toHaveProperty('filter.0.operator')
        expect(router.currentRoute.value.query).toHaveProperty('filter.0.value')

        const primaryNavigationSidebar = view.getByRole('complementary', {
          name: 'Main sidebar',
        })
        const closeSearchTab = within(primaryNavigationSidebar).getByRole('button', {
          name: 'Close this tab',
        })
        await view.events.click(closeSearchTab)

        await waitFor(() => {
          expect(view.queryByRole('button', { name: 'Cancel & go back' })).toBeInTheDocument()
        })

        const confirmationButton = view.getByRole('button', { name: 'Cancel & go back' })
        await view.events.click(confirmationButton) // cancel closing tab

        await waitFor(() => {
          expect(
            within(primaryNavigationSidebar).queryByRole('button', {
              name: 'Close this tab',
            }),
          ).toBeInTheDocument()
          expect(router.currentRoute.value.query.entity).toBe(EnumSearchableModels.Ticket)
          expect(router.currentRoute.value.query).toHaveProperty('filter.0.name')
          expect(router.currentRoute.value.query).toHaveProperty('filter.0.operator')
          expect(router.currentRoute.value.query).toHaveProperty('filter.0.value')
        })
      })
    })
  })
})
