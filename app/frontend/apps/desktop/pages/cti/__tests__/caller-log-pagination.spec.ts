// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { ref } from 'vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import type { CtiLogUpdatesSubscription } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { CtiLogsDocument } from '../graphql/queries/ctiLogs.api.ts'
import { mockCtiLogsQuery } from '../graphql/queries/ctiLogs.mocks.ts'
import { getCtiLogUpdatesSubscriptionHandler } from '../graphql/subscriptions/ctiLogUpdates.mocks.ts'

import { missedCall } from './mocks/caller-log-mocks.ts'

import type { CallerLogEntry } from '../types.ts'

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

// Every call gets its own number, so a row is found by its callable link.
const call = (id: number, overrides: Partial<CallerLogEntry> = {}): CallerLogEntry => ({
  ...missedCall,
  id: convertToGraphQLId('Cti::Log', id),
  from: `49301000${String(id).padStart(4, '0')}`,
  fromPretty: `+49 30 1000${String(id).padStart(4, '0')}`,
  state: 'newCall',
  comment: null,
  done: false,
  fromMatches: [],
  ...overrides,
})

const TOTAL_COUNT = 4

// Newest first: the first page holds the two newest calls, the second the two oldest.
const firstPage = [call(4), call(3)]
const secondPage = [call(2), call(1)]

const page = (entries: CallerLogEntry[], hasNextPage: boolean, totalCount = TOTAL_COUNT) => ({
  ctiLogs: {
    totalCount,
    edges: entries.map((node) => ({ node, cursor: `cursor-${node.id}` })),
    pageInfo: { endCursor: hasNextPage ? 'CURSOR' : null, hasNextPage },
  },
})

const mockPages = (first = firstPage, second = secondPage) =>
  mockCtiLogsQuery(({ cursor }) => (cursor ? page(second, false) : page(first, true)))

const rowIds = (view: Awaited<ReturnType<typeof visitView>>) =>
  Array.from(view.container.querySelectorAll('[data-item-id]')).map((row) =>
    row.getAttribute('data-item-id'),
  )

const getRow = (view: Awaited<ReturnType<typeof visitView>>, entry: CallerLogEntry) =>
  view.container.querySelector(`[data-item-id="${entry.id}"]`) as HTMLElement

const visitCallerLog = async () => {
  const view = await visitView('/cti')

  await view.findByRole('table', { name: 'Caller log' })
  await waitFor(() => expect(getRow(view, firstPage[0])).toBeInTheDocument())

  return view
}

// The auto mocker fills every field left out with generated data, so the two
//   fields an event does not carry have to be null explicitly.
const push = (updates: Partial<CtiLogUpdatesSubscription['ctiLogUpdates']>) =>
  getCtiLogUpdatesSubscriptionHandler().trigger({
    ctiLogUpdates: {
      __typename: 'CtiLogUpdatesPayload',
      addLog: null,
      updateLog: null,
      removeLogId: null,
      ...updates,
    },
  })

const queryCallCount = () => getGraphQLMockCalls(CtiLogsDocument).length

describe('Caller log paging and live updates', () => {
  beforeEach(() => {
    triggerLoadMore = undefined

    mockPermissions(['cti.agent'])
    mockApplicationConfig({ cti_integration: true, user_name_format: 'first_last' })
  })

  it('appends the next page below the loaded one, newest first', async () => {
    mockPages()

    const view = await visitCallerLog()

    expect(rowIds(view)).toEqual([call(4).id, call(3).id])

    await triggerLoadMore?.()

    await waitFor(() => expect(getRow(view, call(1))).toBeInTheDocument())

    expect(rowIds(view)).toEqual([call(4).id, call(3).id, call(2).id, call(1).id])
    expect(getGraphQLMockCalls(CtiLogsDocument).at(-1)?.variables).toEqual({
      cursor: 'CURSOR',
      pageSize: 25,
    })
  })

  describe('with a later page loaded', () => {
    const visitWithBothPages = async () => {
      mockPages()

      const view = await visitCallerLog()

      await triggerLoadMore?.()
      await waitFor(() => expect(getRow(view, call(1))).toBeInTheDocument())

      return view
    }

    it('re-renders an updated row on the first page without asking the server', async () => {
      const view = await visitWithBothPages()
      const callsBefore = queryCallCount()

      expect(within(getRow(view, call(3))).getByText('Ringing…')).toBeInTheDocument()

      await push({ updateLog: call(3, { state: 'answer' }) })

      await waitFor(() =>
        expect(within(getRow(view, call(3))).getByText('Connected')).toBeInTheDocument(),
      )
      expect(queryCallCount()).toBe(callsBefore)
    })

    it('re-renders an updated row on a later page without asking the server', async () => {
      const view = await visitWithBothPages()
      const callsBefore = queryCallCount()

      await push({ updateLog: call(1, { state: 'answer' }) })

      await waitFor(() =>
        expect(within(getRow(view, call(1))).getByText('Connected')).toBeInTheDocument(),
      )
      expect(rowIds(view)).toEqual([call(4).id, call(3).id, call(2).id, call(1).id])
      expect(queryCallCount()).toBe(callsBefore)
    })

    it('drops a removed row locally when everything is loaded', async () => {
      const view = await visitWithBothPages()
      const callsBefore = queryCallCount()

      await push({ removeLogId: call(3).id })

      await waitFor(() => expect(getRow(view, call(3))).toBeNull())

      expect(rowIds(view)).toEqual([call(4).id, call(2).id, call(1).id])
      expect(queryCallCount()).toBe(callsBefore)
    })

    it('puts an added call at the top while the agent is scrolled down', async () => {
      const view = await visitWithBothPages()
      const callsBefore = queryCallCount()

      await push({ addLog: call(10) })

      await waitFor(() => expect(getRow(view, call(10))).toBeInTheDocument())

      expect(rowIds(view)).toEqual([call(10).id, call(4).id, call(3).id, call(2).id, call(1).id])
      expect(queryCallCount()).toBe(callsBefore)
    })
  })

  it('reads the loaded window again when a visible row is removed and more pages exist', async () => {
    mockPages()

    const view = await visitCallerLog()

    // The server no longer has the removed call, so the first page starts with the next one.
    mockCtiLogsQuery(({ cursor }) =>
      cursor ? page([call(1)], false, 3) : page([call(4), call(2)], true, 3),
    )

    await push({ removeLogId: call(3).id })

    await waitFor(() => expect(getRow(view, call(2))).toBeInTheDocument())

    // The table may fetch the next page on its own once the shorter list leaves room,
    //   so only the head of the list and the refetch itself are asserted.
    expect(rowIds(view).slice(0, 2)).toEqual([call(4).id, call(2).id])
    expect(rowIds(view)).not.toContain(call(3).id)
    expect(
      getGraphQLMockCalls(CtiLogsDocument).map((mockCall) => mockCall.variables),
    ).toContainEqual({ cursor: null, pageSize: 25 })
  })

  // The cursors encode offsets: a call added at the top shifts the rest of the list by one,
  //   so the next page starts with the row loaded last. The list must not show it twice.
  it('does not duplicate the last loaded row on the page after an added call', async () => {
    mockPages(firstPage, [call(3), call(2)])

    const view = await visitCallerLog()

    await push({ addLog: call(10) })

    await waitFor(() => expect(getRow(view, call(10))).toBeInTheDocument())

    await triggerLoadMore?.()

    await waitFor(() => expect(getRow(view, call(2))).toBeInTheDocument())

    expect(rowIds(view)).toEqual([call(10).id, call(4).id, call(3).id, call(2).id])
  })
})
