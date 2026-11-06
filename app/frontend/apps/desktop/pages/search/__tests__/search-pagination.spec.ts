// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'
import { ref } from 'vue'

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import useMetaTitle from '#shared/composables/useMetaTitle.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import type { DetailSearchQueryVariables } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockDetailSearchQuery,
  waitForDetailSearchQueryCalls,
} from '#desktop/components/Search/graphql/queries/detailSearch.mocks.ts'

// The infinite scroll is driven by @vueuse/core; capture its callback so the
//   test can simulate the agent reaching the end of the list.
let triggerLoadMore: (() => Promise<void>) | undefined

vi.mock('@vueuse/core', async (importOriginal) => {
  const modules = await importOriginal<typeof import('@vueuse/core')>()

  return {
    ...modules,
    useInfiniteScroll: (_element: unknown, callback: () => Promise<void>) => {
      triggerLoadMore = callback
      return { reset: vi.fn(), isLoading: ref(false) }
    },
  }
})

const PAGE_SIZE = 30

const firstPage = {
  search: {
    totalCount: 1,
    items: [createDummyTicket({ ticketId: convertToGraphQLId('Ticket', 1) })],
  },
}

// Answers the first page right away and leaves a next page to `nextPage`.
const mockPages = (nextPage: () => Promise<never> | typeof firstPage) =>
  mockDetailSearchQuery(({ offset }: DetailSearchQueryVariables) =>
    offset ? nextPage() : firstPage,
  )

const failedPage = () => Promise.reject(new Error('Connection lost'))

const visitSearchView = async () => {
  const view = await visitView('/search/test')

  await waitForDetailSearchQueryCalls()

  const searchInput = within(view.getByTestId('search-container')).getByRole('searchbox', {
    name: 'Search…',
  })

  return { view, searchInput }
}

const waitForDetailSearchQueryCallCount = async (count: number) => {
  await waitFor(async () => expect(await waitForDetailSearchQueryCalls()).toHaveLength(count))

  return waitForDetailSearchQueryCalls()
}

describe('search pagination', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
    useMetaTitle().initializeMetaTitle()
  })

  it('requests the same page again after a failed next page', async () => {
    let nextPageFails = true

    mockPages(() => (nextPageFails ? failedPage() : firstPage))

    await visitSearchView()

    await triggerLoadMore?.()

    const failedCalls = await waitForDetailSearchQueryCallCount(2)

    expect(failedCalls.at(-1)?.variables).toMatchObject({ offset: PAGE_SIZE, search: 'test' })

    nextPageFails = false

    await triggerLoadMore?.()

    const retriedCalls = await waitForDetailSearchQueryCallCount(3)

    expect(retriedCalls.at(-1)?.variables).toMatchObject({ offset: PAGE_SIZE, search: 'test' })
  })

  it('restarts from the first page of a changed search term when the pending page fails', async () => {
    let holdNextPage = true
    let failPendingPage!: (error: Error) => void

    mockPages(() =>
      holdNextPage
        ? new Promise<never>((_resolve, reject) => {
            failPendingPage = reject
          })
        : firstPage,
    )

    const { view, searchInput } = await visitSearchView()

    const pendingPage = triggerLoadMore?.()

    await waitForDetailSearchQueryCallCount(2)

    const router = getTestRouter()

    await view.events.type(searchInput, 'ing')

    await waitFor(() =>
      expect(router.currentRoute.value.fullPath).toBe('/search/testing?entity=Ticket'),
    )

    // The new term's first page, requested while the old term's next page is still pending.
    const restartedCalls = await waitForDetailSearchQueryCallCount(3)

    expect(restartedCalls.at(-1)?.variables).toMatchObject({ search: 'testing' })
    expect(restartedCalls.at(-1)?.variables).not.toHaveProperty('offset')

    holdNextPage = false
    failPendingPage(new Error('Connection lost'))

    await pendingPage

    await triggerLoadMore?.()

    const nextPageCalls = await waitForDetailSearchQueryCallCount(4)

    // Not offset 0 - the first page of the new term is already loaded.
    expect(nextPageCalls.at(-1)?.variables).toMatchObject({ offset: PAGE_SIZE, search: 'testing' })
  })
})
