// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { setActivePinia, createPinia, storeToRefs } from 'pinia'

import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { UserData } from '#shared/types/store.ts'

import { waitForUserCurrentTicketOverviewsQueryCalls } from '#desktop/entities/ticket/graphql/queries/userCurrentTicketOverviews.mocks.ts'
import type { TicketOverviewQueryPollingConfig } from '#desktop/entities/ticket/stores/types.ts'
import { mockUserCurrentOverviewListQuery } from '#desktop/pages/personal-setting/graphql/queries/userCurrentOverviewList.mocks.ts'

import { useTicketOverviewsStore } from '../ticketOverviews.ts'

vi.mock('#shared/server/apollo/client.ts', () => ({
  getApolloClient: () => ({
    cache: {
      writeQuery: vi.fn(),
      readQuery: vi.fn(),
    },
  }),
}))

describe('useTicketOverviewsStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  describe('customer user', () => {
    beforeEach(() => {
      mockPermissions(['ticket.customer'])
    })

    it('initializes with default values', async () => {
      const store = useTicketOverviewsStore()

      const {
        overviews,
        overviewsSortedByLastUsedIds,
        hasOverviews,
        overviewsLoading,
        currentTicketOverviewLink,
        ticketsByOverviewHandler,
        overviewBackgroundPollingIds,
        overviewBackgroundCountPollingIds,
      } = store

      expect(store).toBeDefined()
      expect(overviews).toEqual([])
      expect(overviewsSortedByLastUsedIds).toEqual([])
      expect(overviewsLoading).toBe(true)
      expect(hasOverviews).toBe(false)
      expect(currentTicketOverviewLink).toBe('')
      expect(ticketsByOverviewHandler).toEqual(new Map())
      expect(overviewBackgroundPollingIds).toEqual([])
      expect(overviewBackgroundCountPollingIds).toEqual([])
    })

    it('returns values as soon as loading has completed', async () => {
      const store = storeToRefs(useTicketOverviewsStore())

      const {
        overviews,
        overviewsSortedByLastUsedIds,
        hasOverviews,
        overviewsLoading,
        currentTicketOverviewLink,
        ticketsByOverviewHandler,
        overviewBackgroundPollingIds,
        overviewBackgroundCountPollingIds,
      } = store

      await waitFor(() => expect(overviewsLoading.value).toBe(false))

      // auto-mocked data
      expect(overviews.value.length).not.toBe(0)
      expect(overviewsSortedByLastUsedIds.value).not.toBe(0)
      expect(hasOverviews.value).toBe(true)
      expect(currentTicketOverviewLink.value).toBe('')
      expect(ticketsByOverviewHandler.value).toEqual(new Map())
      expect(overviewBackgroundPollingIds.value).toEqual([])
      expect(overviewBackgroundCountPollingIds.value).toEqual(
        expect.arrayContaining([expect.stringContaining('gid://zammad/Overview')]),
      )
    })
  })
  describe('as admin user', () => {
    beforeEach(() => {
      mockPermissions(['admin.user'])
    })

    it('initializes with default values', async () => {
      const store = useTicketOverviewsStore()

      const {
        overviews,
        overviewsSortedByLastUsedIds,
        hasOverviews,
        currentTicketOverviewLink,
        ticketsByOverviewHandler,
        overviewBackgroundPollingIds,
        overviewBackgroundCountPollingIds,
      } = store

      expect(store).toBeDefined()
      expect(overviews).toEqual([])
      expect(overviewsSortedByLastUsedIds).toEqual([])
      expect(hasOverviews).toBe(false)
      expect(currentTicketOverviewLink).toBe('')
      expect(ticketsByOverviewHandler).toEqual(new Map())
      expect(overviewBackgroundPollingIds).toEqual([])
      expect(overviewBackgroundCountPollingIds).toEqual([])
    })

    it('has no access to ticket overviews without agent permission', async () => {
      const store = storeToRefs(useTicketOverviewsStore())

      const {
        overviews,
        overviewsSortedByLastUsedIds,
        hasOverviews,
        overviewsLoading,
        overviewBackgroundCountPollingIds,
      } = store

      await waitFor(() => expect(overviewsLoading.value).toBe(false))

      // Admin without ticket.agent should not have access to overviews
      expect(overviews.value).toEqual([])
      expect(overviewsSortedByLastUsedIds.value).toEqual([])
      expect(hasOverviews.value).toBe(false)
      expect(overviewBackgroundCountPollingIds.value).toEqual([])
    })
  })

  describe('agent user', () => {
    beforeEach(() => {
      mockPermissions(['ticket.agent'])
    })

    it('initializes with default values', async () => {
      const store = useTicketOverviewsStore()

      const {
        overviews,
        overviewsSortedByLastUsedIds,
        hasOverviews,
        overviewsLoading,
        currentTicketOverviewLink,
        ticketsByOverviewHandler,
        overviewBackgroundPollingIds,
        overviewBackgroundCountPollingIds,
      } = store

      expect(store).toBeDefined()
      expect(overviews).toEqual([])
      expect(overviewsSortedByLastUsedIds).toEqual([])
      expect(overviewsLoading).toBe(true)
      expect(hasOverviews).toBe(false)
      expect(currentTicketOverviewLink).toBe('')
      expect(ticketsByOverviewHandler).toEqual(new Map())
      expect(overviewBackgroundPollingIds).toEqual([])
      expect(overviewBackgroundCountPollingIds).toEqual([])
    })

    it('computes overviewBackgroundPollingIds correctly', async () => {
      mockUserCurrentOverviewListQuery({
        userCurrentTicketOverviews: [
          {
            name: 'overview-1',
            id: convertToGraphQLId('Overview', 1),
            organizationShared: false,
            outOfOffice: false,
          },
          {
            name: 'overview-2',
            id: convertToGraphQLId('Overview', 2),
            organizationShared: false,
            outOfOffice: false,
          },
        ],
      })
      const store = useTicketOverviewsStore()
      const { currentTicketOverviewLink, overviewBackgroundPollingIds } = storeToRefs(store)

      store.setCurrentTicketOverviewLink('overview-1')

      expect(currentTicketOverviewLink.value).toBe('overview-1')

      expect(overviewBackgroundPollingIds.value).toEqual([])

      // As soon as we set change the overview the previous overview should be queued for the background polling
      store.setCurrentTicketOverviewLink('overview-2')

      await waitFor(() =>
        expect(overviewBackgroundPollingIds.value).toEqual([convertToGraphQLId('Overview', 1)]),
      )
    })

    it('returns values as soon as loading has completed', async () => {
      const store = storeToRefs(useTicketOverviewsStore())

      const {
        overviews,
        overviewsSortedByLastUsedIds,
        hasOverviews,
        overviewsLoading,
        currentTicketOverviewLink,
        ticketsByOverviewHandler,
        overviewBackgroundPollingIds,
        overviewBackgroundCountPollingIds,
      } = store

      await waitFor(() => expect(overviewsLoading.value).toBe(false))

      // auto-mocked data
      expect(overviews.value.length).not.toBe(0)
      expect(overviewsSortedByLastUsedIds.value).not.toBe(0)
      expect(hasOverviews.value).toBe(true)
      expect(currentTicketOverviewLink.value).toBe('')
      expect(ticketsByOverviewHandler.value).toEqual(new Map())
      expect(overviewBackgroundPollingIds.value).toEqual([])
      expect(overviewBackgroundCountPollingIds.value).toEqual(
        expect.arrayContaining([expect.stringContaining('gid://zammad/Overview')]),
      )
    })

    it('returns the default queryPollingConfig', async () => {
      const store = useTicketOverviewsStore()
      const { queryPollingConfig } = storeToRefs(store)

      expect(queryPollingConfig.value).toBeDefined()
      expect(queryPollingConfig.value.enabled).toBe(true)
      expect(queryPollingConfig.value.page_size).toBe(30)
      expect(queryPollingConfig.value.background).toEqual({
        calculation_count: 3,
        interval_sec: 10,
        cache_ttl_sec: 10,
        interval_ranges: [
          { threshold_sec: 60 * 60, interval_sec: 15, cache_ttl_sec: 15 }, // 1 hour ago
          { threshold_sec: 2 * 60 * 60, interval_sec: 20, cache_ttl_sec: 20 }, // 2 hours ago
          { threshold_sec: 4 * 60 * 60, interval_sec: 30, cache_ttl_sec: 30 }, // 4 hour ago
          { threshold_sec: 12 * 60 * 60, interval_sec: 45, cache_ttl_sec: 45 }, // 12 hours ago
          { threshold_sec: 24 * 60 * 60, interval_sec: 60, cache_ttl_sec: 60 }, // 1 day ago
          { threshold_sec: 3 * 24 * 60 * 60, interval_sec: 120, cache_ttl_sec: 120 }, // 3 days ago
          { threshold_sec: 7 * 24 * 60 * 60, interval_sec: 180, cache_ttl_sec: 180 }, // 1 week ago
        ],
      })
      expect(queryPollingConfig.value.foreground).toEqual({
        interval_sec: 5,
        cache_ttl_sec: 5,
      })
      expect(queryPollingConfig.value.counts).toEqual({
        interval_sec: 60,
        cache_ttl_sec: 60,
      })
    })

    it('allows modifying the polling config on runtime', async () => {
      const store = useTicketOverviewsStore()
      const { queryPollingConfig } = storeToRefs(store)
      expect(queryPollingConfig.value.page_size).toBe(30)

      const updatedPollingConfig: TicketOverviewQueryPollingConfig = {
        enabled: false,
        page_size: 50,
        background: {
          calculation_count: 3,
          interval_sec: 10,
          cache_ttl_sec: 10,
          interval_ranges: [],
        },
        foreground: {
          interval_sec: 10,
          cache_ttl_sec: 10,
        },
        counts: {
          interval_sec: 10,
          cache_ttl_sec: 10,
        },
      }
      setQueryPollingConfig(updatedPollingConfig)

      expect(queryPollingConfig.value).toEqual(updatedPollingConfig)
    })

    it('returns the correct overviewsByLink', async () => {
      const store = useTicketOverviewsStore()
      const { overviewsByLink } = storeToRefs(store)

      await waitFor(() => expect(Object.keys(overviewsByLink.value).length).toBeGreaterThan(0))
    })

    it('sets the current ticket overview link correctly', async () => {
      const store = useTicketOverviewsStore()
      const { currentTicketOverviewLink } = storeToRefs(store)

      store.setCurrentTicketOverviewLink('new-overview-link')

      expect(currentTicketOverviewLink.value).toBe('new-overview-link')
    })

    it('adds and removes ticket handlers correctly', async () => {
      mockUserCurrentOverviewListQuery({
        userCurrentTicketOverviews: [
          {
            name: 'overview-1',
            id: convertToGraphQLId('Overview', 1),
            organizationShared: false,
            outOfOffice: false,
          },
          {
            name: 'overview-2',
            id: convertToGraphQLId('Overview', 2),
            organizationShared: false,
            outOfOffice: false,
          },
        ],
      })

      const store = useTicketOverviewsStore()
      const { ticketsByOverviewHandler, overviewsById } = storeToRefs(store)

      await waitForUserCurrentTicketOverviewsQueryCalls()

      // Initially, there should be no handlers
      expect(ticketsByOverviewHandler.value.size).toBe(0)

      await waitFor(() => expect(overviewsById.value).not.toEqual(new Set())) // wait for updates

      // Add the handler
      store.addTicketByOverviewHandler(convertToGraphQLId('Overview', 1))

      expect(ticketsByOverviewHandler.value.size).toBe(1)

      expect(ticketsByOverviewHandler.value.has(convertToGraphQLId('Overview', 1))).toBe(true)

      // Remove the handler
      store.removeTicketByOverviewHandler(convertToGraphQLId('Overview', 1))

      expect(ticketsByOverviewHandler.value.size).toBe(0)

      expect(ticketsByOverviewHandler.value.has(convertToGraphQLId('Overview', 1))).toBe(false)
    })

    it('updates last used overview correctly', async () => {
      mockUserCurrentOverviewListQuery({
        userCurrentTicketOverviews: [
          {
            name: 'overview-1',
            id: convertToGraphQLId('Overview', 1),
            organizationShared: false,
            outOfOffice: false,
          },
          {
            name: 'overview-2',
            id: convertToGraphQLId('Overview', 2),
            organizationShared: false,
            outOfOffice: false,
          },
        ],
      })

      const store = useTicketOverviewsStore()
      const { lastUsedOverviews, overviewsById } = storeToRefs(store)

      const { user } = storeToRefs(useSessionStore())

      // Skip mocking and write directly to the store
      user.value = {
        ...user.value,
        preferences: {
          overviews_last_used: {
            2: '2021-09-02T00:00:00Z',
          },
        },
      } as UserData

      await waitFor(() => expect(overviewsById.value).not.toEqual({})) // wait for updates

      await store.updateLastUsedOverview(convertToGraphQLId('Overview', 1))

      // Check if the last used overview is updated correctly
      await waitFor(() =>
        expect(lastUsedOverviews.value[convertToGraphQLId('Overview', 1)]).toBeDefined(),
      )

      expect(user.value!.preferences.overviews_last_used['1']).toBeDefined()
    })

    it('updates last used overview also for initial entry correctly', async () => {
      mockUserCurrentOverviewListQuery({
        userCurrentTicketOverviews: [
          {
            name: 'overview-1',
            id: convertToGraphQLId('Overview', 1),
            organizationShared: false,
            outOfOffice: false,
          },
          {
            name: 'overview-2',
            id: convertToGraphQLId('Overview', 2),
            organizationShared: false,
            outOfOffice: false,
          },
        ],
      })

      const store = useTicketOverviewsStore()
      const { lastUsedOverviews, overviewsById } = storeToRefs(store)

      const { user } = storeToRefs(useSessionStore())

      // Skip mocking and write directly to the store
      user.value = {
        ...user.value,
        preferences: {},
      } as UserData

      await waitFor(() => expect(overviewsById.value).not.toEqual({})) // wait for updates

      await store.updateLastUsedOverview(convertToGraphQLId('Overview', 1))

      // Check if the last used overview is updated correctly
      await waitFor(() =>
        expect(lastUsedOverviews.value[convertToGraphQLId('Overview', 1)]).toBeDefined(),
      )

      expect(user.value!.preferences.overviews_last_used['1']).toBeDefined()
    })
  })
})
