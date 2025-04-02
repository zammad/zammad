// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import gql from 'graphql-tag'

import type { TicketsCachedByOverviewQueryVariables } from '#shared/graphql/types.ts'
import registerRelayStylePagination from '#shared/server/apollo/cache/utils/registerRelayStylePagination.ts'

import { useTicketsCachedByOverviewCache } from '#desktop/entities/ticket/composables/useTicketsCachedByOverviewCache.ts'

import type { InMemoryCache } from '@apollo/client/cache'
import type {
  FieldMergeFunction,
  FieldPolicy,
} from '@apollo/client/cache/inmemory/policies'
import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

const modifyOverviewsCache = (
  cache: InMemoryCache,
  { ticketCount, overviewId }: { ticketCount: number; overviewId: string },
) => {
  const normalizedId = cache.identify({
    id: overviewId,
    __typename: 'Overview',
  })

  // Check if the cache already has this field.
  const existingData = cache.readFragment<{ cachedTicketCount: number }>({
    id: normalizedId,
    fragment: gql`
      fragment TicketCountFragment on Overview {
        cachedTicketCount(cacheTtl: 60)
      }
    `,
  })

  if (existingData && existingData.cachedTicketCount === ticketCount) return

  cache.writeFragment({
    id: normalizedId,
    fragment: gql`
      fragment TicketCountFragment on Overview {
        cachedTicketCount(cacheTtl: 60)
      }
    `,
    data: {
      cachedTicketCount: ticketCount,
    },
  })
}

export default function register(
  config: InMemoryCacheConfig,
): InMemoryCacheConfig {
  const currentConfig = registerRelayStylePagination(
    config,
    'ticketsCachedByOverview',
    ['overviewId', 'orderBy', 'orderDirection'],
  )

  currentConfig.typePolicies ||= {}
  currentConfig.typePolicies.Query ||= {}
  currentConfig.typePolicies.Query.fields ||= {}

  // Assert that ticketsCachedByOverview is a FieldPolicy
  const ticketsCachedByOverviewPolicy = currentConfig.typePolicies.Query.fields
    .ticketsCachedByOverview as FieldPolicy

  const originalMerge =
    ticketsCachedByOverviewPolicy.merge as FieldMergeFunction

  // Override merge function to include noChange handling
  ticketsCachedByOverviewPolicy.merge = (existing, incoming, options) => {
    const { cache, variables } = options

    const overviewId = variables?.overviewId as string

    if (overviewId && incoming.totalCount !== undefined) {
      modifyOverviewsCache(cache, {
        ticketCount: incoming.totalCount,
        overviewId,
      })
    }

    const cachedData =
      useTicketsCachedByOverviewCache().readTicketsByOverviewCache(
        variables as TicketsCachedByOverviewQueryVariables,
      )

    // We receiving null when the query data is still the same.
    if ((cachedData || existing) && incoming.edges === null) {
      // TODO: Returning cache data destroys currently the references on the tickets...
      // TODO: And workaround with "existing" is not working, because also with cache+network it's always empty.
      return existing || cachedData!.ticketsCachedByOverview // Return existing data without updating
    }

    // Otherwise, call the original merge function for normal pagination behavior
    return originalMerge(existing, incoming, options)
  }

  return currentConfig
}
