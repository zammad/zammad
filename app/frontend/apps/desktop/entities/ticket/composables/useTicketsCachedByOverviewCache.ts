// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type {
  TicketsCachedByOverviewQuery,
  TicketsCachedByOverviewQueryVariables,
} from '#shared/graphql/types'
import { getApolloClient } from '#shared/server/apollo/client.ts'

import { TicketsCachedByOverviewDocument } from '../graphql/queries/ticketsCachedByOverview.api.ts'

export const useTicketsCachedByOverviewCache = () => {
  const apolloClient = getApolloClient()

  const readTicketsByOverviewCache = (
    variables: TicketsCachedByOverviewQueryVariables,
  ) => {
    return apolloClient.readQuery<TicketsCachedByOverviewQuery>({
      query: TicketsCachedByOverviewDocument,
      variables,
    })
  }

  const writeTicketsByOverviewCache = (
    variables: TicketsCachedByOverviewQueryVariables,
    data: TicketsCachedByOverviewQuery,
  ) => {
    return apolloClient.writeQuery<TicketsCachedByOverviewQuery>({
      query: TicketsCachedByOverviewDocument,
      variables,
      data,
    })
  }

  const forceTicketsByOverviewCacheOnlyFirstPage = (
    variables: TicketsCachedByOverviewQueryVariables,
    collectionSignature: string,
    pageSize: number,
  ) => {
    const currentTicketsCachedByOverview = readTicketsByOverviewCache(variables)

    if (!currentTicketsCachedByOverview) return

    const currentTickets =
      currentTicketsCachedByOverview?.ticketsCachedByOverview?.edges

    const currentTicketsEdgesCount = currentTickets?.length

    if (!currentTicketsEdgesCount || currentTicketsEdgesCount <= pageSize)
      return

    const slicedTickets = currentTickets?.slice(0, pageSize)

    writeTicketsByOverviewCache(variables, {
      ticketsCachedByOverview: {
        ...currentTicketsCachedByOverview.ticketsCachedByOverview,
        collectionSignature,
        edges: slicedTickets,
        pageInfo: {
          ...currentTicketsCachedByOverview.ticketsCachedByOverview.pageInfo,
          hasNextPage: true,
          endCursor: slicedTickets[slicedTickets.length - 1].cursor,
        },
      },
    })
  }

  return {
    readTicketsByOverviewCache,
    writeTicketsByOverviewCache,
    forceTicketsByOverviewCacheOnlyFirstPage,
  }
}
