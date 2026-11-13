// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { mockedApolloClient } from '#tests/graphql/builders/mocks.ts'
import ticketObjectAttributes from '#tests/graphql/factories/fixtures/ticket-object-attributes.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/core/attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'

import {
  mockDetailSearchQuery,
  waitForDetailSearchQueryCalls,
} from '#desktop/components/Search/graphql/queries/detailSearch.mocks.ts'
import { waitForSearchCountsQueryCalls } from '#desktop/components/Search/graphql/queries/searchCounts.mocks.ts'
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

const waitForSearchCalls = () =>
  Promise.all([waitForDetailSearchQueryCalls(), waitForSearchCountsQueryCalls()])

// Refetches every query that is running; a stopped query sends nothing.
const refetchRunningQueries = async () => {
  await mockedApolloClient.refetchObservableQueries()
  await waitForNextTick()
}

describe('SearchContent lazy queries', () => {
  beforeEach(async () => {
    mockPermissions(['ticket.agent'])
    mockDetailSearchQuery({ search: { totalCount: 0, items: [] } })

    const router = getTestRouter()
    if (router) await router.push('/')
  })

  it('loads the detail and the counts query on the first search', async () => {
    renderSearchContent({ searchTerm: 'ticket' })

    const [detailCalls, countsCalls] = await waitForSearchCalls()

    expect(detailCalls).toHaveLength(1)
    expect(detailCalls[0].variables).toMatchObject({ search: 'ticket' })
    expect(countsCalls).toHaveLength(1)
    expect(countsCalls[0].variables).toMatchObject({ search: 'ticket' })
  })

  it('stops both queries when the search is no longer active', async () => {
    const wrapper = renderSearchContent({ searchTerm: 'ticket' })

    const [detailCalls, countsCalls] = await waitForSearchCalls()

    await wrapper.rerender({ searchTerm: '' })
    await refetchRunningQueries()

    expect(detailCalls).toHaveLength(1)
    expect(countsCalls).toHaveLength(1)
  })

  it('sends a request again for a search after the queries were stopped', async () => {
    const wrapper = renderSearchContent({ searchTerm: 'ticket' })

    const [detailCalls, countsCalls] = await waitForSearchCalls()

    await wrapper.rerender({ searchTerm: '' })
    await waitForNextTick()

    await wrapper.rerender({ searchTerm: 'another ticket' })

    await vi.waitFor(() => {
      expect(detailCalls).toHaveLength(2)
      expect(countsCalls).toHaveLength(2)
    })

    expect(detailCalls.at(-1)?.variables).toMatchObject({ search: 'another ticket' })
    expect(countsCalls.at(-1)?.variables).toMatchObject({ search: 'another ticket' })
  })

  it('loads both queries on the first search when the page started without a search', async () => {
    const wrapper = renderSearchContent()

    await wrapper.findByRole('tab', { name: 'Ticket' })
    await refetchRunningQueries()

    await wrapper.rerender({ searchTerm: 'ticket' })

    const [detailCalls, countsCalls] = await waitForSearchCalls()

    expect(detailCalls).toHaveLength(1)
    expect(detailCalls[0].variables).toMatchObject({ search: 'ticket' })
    expect(countsCalls).toHaveLength(1)
    expect(countsCalls[0].variables).toMatchObject({ search: 'ticket' })
  })
})
