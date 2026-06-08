// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { afterEach, beforeEach } from 'vitest'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { waitForTicketsCachedByOverviewQueryCalls } from '#desktop/entities/ticket/graphql/queries/ticketsCachedByOverview.mocks.ts'
import { waitForUserCurrentTicketOverviewsQueryCalls } from '#desktop/entities/ticket/graphql/queries/userCurrentTicketOverviews.mocks.ts'

import {
  mockDefaultOverviewQueries,
  mockDefaultTicketsCachedByOverview,
} from './mocks/ticket-overviews-mocks.ts'

describe('Ticket Overviews > Polling', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('polls for the active overviews', async () => {
    mockDefaultOverviewQueries()
    mockDefaultTicketsCachedByOverview()

    mockUserCurrent({
      permissions: {
        names: ['ticket.agent'],
      },
      preferences: {
        overviews_last_used: {},
      },
    })

    mockApplicationConfig({
      ui_ticket_overview_query_polling: {
        enabled: true,
        page_size: 30,
        background: {
          calculation_count: 0,
          interval_sec: 0,
          cache_ttl_sec: 0,
        },
        foreground: {
          interval_sec: 1,
          cache_ttl_sec: 1,
        },
        counts: {
          interval_sec: 0,
          cache_ttl_sec: 0,
        },
      },
    })

    await visitView('tickets/view/my_assigned')

    await waitForUserCurrentTicketOverviewsQueryCalls()

    const mocks = await waitForTicketsCachedByOverviewQueryCalls()
    expect(mocks).toHaveLength(1)

    await vi.advanceTimersByTimeAsync(1500)
    await waitForNextTick()

    expect(mocks).toHaveLength(2)
  })

  it('polls for the background overviews', async () => {
    mockDefaultOverviewQueries()
    mockDefaultTicketsCachedByOverview()

    mockUserCurrent({
      permissions: {
        names: ['ticket.agent'],
      },
      preferences: {
        overviews_last_used: {
          '2': new Date().toISOString(),
        },
      },
    })

    mockApplicationConfig({
      ui_ticket_overview_query_polling: {
        enabled: true,
        page_size: 30,
        background: {
          calculation_count: 3,
          interval_sec: 5,
          cache_ttl_sec: 5,
        },
        foreground: {
          interval_sec: 1000,
          cache_ttl_sec: 1000,
        },
        counts: {
          interval_sec: 1000,
          cache_ttl_sec: 1000,
        },
      },
    })

    await visitView('tickets/view/my_assigned')

    await waitForUserCurrentTicketOverviewsQueryCalls()

    const mocks = await waitForTicketsCachedByOverviewQueryCalls()
    expect(mocks).toHaveLength(2)

    await vi.advanceTimersByTimeAsync(6000)
    await waitForNextTick()

    expect(mocks).toHaveLength(3)
  })

  it('disables polling when the config is disabled', async () => {
    mockDefaultOverviewQueries()
    mockDefaultTicketsCachedByOverview()

    mockApplicationConfig({
      ui_ticket_overview_query_polling: {
        enabled: false,
        page_size: 30,
        background: {
          calculation_count: 3,
          interval_sec: 5,
          cache_ttl_sec: 5,
        },
        foreground: {
          interval_sec: 0,
          cache_ttl_sec: 0,
        },
        counts: {
          interval_sec: 0,
          cache_ttl_sec: 0,
        },
      },
    })

    await visitView('tickets/view/my_assigned')

    const mocks = await waitForTicketsCachedByOverviewQueryCalls()

    expect(mocks).toHaveLength(1)

    await vi.advanceTimersByTimeAsync(5000)
    await vi.advanceTimersToNextTimerAsync()

    expect(mocks).toHaveLength(1)
  })
})
