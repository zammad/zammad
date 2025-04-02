// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { EffectScope } from 'vue'

import type {
  TicketsCachedByOverviewQuery,
  TicketsCachedByOverviewQueryVariables,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

export interface TicketsByOverviewHandlerItem {
  queryHandler: QueryHandler<
    TicketsCachedByOverviewQuery,
    TicketsCachedByOverviewQueryVariables
  >
  scope: EffectScope
}

export type TicketOverviewQueryPollingConfig = {
  enabled: boolean
  page_size: number
  background: {
    calculation_count: number
    interval_sec: number
    cache_ttl_sec: number
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
