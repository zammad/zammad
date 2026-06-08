// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EffectScope } from 'vue'

import type {
  TicketsCachedByOverviewQuery,
  TicketsCachedByOverviewQueryVariables,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

export interface TicketsByOverviewHandlerItem {
  queryHandler: QueryHandler<TicketsCachedByOverviewQuery, TicketsCachedByOverviewQueryVariables>
  scope: EffectScope
}

export type TicketOverviewQueryPollingIntervalRange = {
  threshold_sec: number // Time in seconds since last used
  interval_sec: number // Polling interval to use when threshold is exceeded
  cache_ttl_sec?: number // Optional: Cache TTL to use when threshold is exceeded (falls back to default if not specified)
}

/**
 * Configuration for ticket overview query polling.
 *
 * The background.interval_ranges property allows for dynamic polling intervals based on
 * when an overview was last used. Ranges should be sorted by threshold_sec in ascending order.
 *
 * Example configuration:
 * ```typescript
 * {
 *   background: {
 *     interval_sec: 10,     // Default for recently used overviews
 *     cache_ttl_sec: 10,    // Default cache TTL
 *     interval_ranges: [
 *       { threshold_sec: 3600,   interval_sec: 30,  cache_ttl_sec: 30 },   // 1 hour ago -> 30s polling, 30s cache
 *       { threshold_sec: 86400,  interval_sec: 60,  cache_ttl_sec: 60 },   // 1 day ago -> 60s polling, 60s cache
 *       { threshold_sec: 604800, interval_sec: 120, cache_ttl_sec: 120 },  // 1 week ago -> 120s polling, 120s cache
 *     ]
 *   }
 * }
 * ```
 *
 * Note: cache_ttl_sec in ranges is optional. If omitted, the default background.cache_ttl_sec is used.
 *
 * If interval_ranges is not defined or empty, the default interval_sec is used for all overviews.
 */
export type TicketOverviewQueryPollingConfig = {
  enabled: boolean
  page_size: number
  background: {
    calculation_count: number
    interval_sec: number // Default interval (used when no ranges defined or overview was never used)
    cache_ttl_sec: number
    interval_ranges?: TicketOverviewQueryPollingIntervalRange[] // Optional: dynamic intervals based on last used time
  }
  foreground: {
    interval_sec: number
    cache_ttl_sec: number
  }
  counts: {
    interval_sec: number
    cache_ttl_sec: number
  }
}
