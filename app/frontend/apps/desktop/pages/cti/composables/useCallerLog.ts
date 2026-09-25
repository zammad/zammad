// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, nextTick, type Ref } from 'vue'

import { usePagination } from '#shared/composables/usePagination.ts'
import type {
  CtiLogsQuery,
  CtiLogUpdatesSubscription,
  CtiLogUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { getApolloClient } from '#shared/server/apollo/client.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { edgesToArray } from '#shared/utils/helpers.ts'

import { useCtiLogsQuery } from '../graphql/queries/ctiLogs.api.ts'
import { CtiLogUpdatesDocument } from '../graphql/subscriptions/ctiLogUpdates.api.ts'

export const CALLER_LOG_PAGE_SIZE = 25

type Connection = CtiLogsQuery['ctiLogs']

export const useCallerLog = (enabled: Ref<boolean>) => {
  const logsQuery = new QueryHandler(
    useCtiLogsQuery({ pageSize: CALLER_LOG_PAGE_SIZE }, () => ({
      enabled: enabled.value,
      fetchPolicy: 'cache-and-network',
    })),
    {
      // The view has its own error state, so the generic notification stays quiet.
      errorCallback: () => false,
    },
  )

  const logsResult = logsQuery.result()
  const loading = logsQuery.loadingWithoutCachedResult()
  const error = logsQuery.operationError()

  const logs = computed(() => edgesToArray(logsResult.value?.ctiLogs))
  const totalCount = computed(() => logsResult.value?.ctiLogs.totalCount ?? 0)

  const pagination = usePagination(logsQuery, 'ctiLogs', CALLER_LOG_PAGE_SIZE)

  // Refetching a single page would collapse a scrolled list back to its first one, so a
  //   refetch covers every page loaded so far and replaces the loaded window one for one.
  const loadedPageSize = () =>
    Math.max(Math.ceil(logs.value.length / CALLER_LOG_PAGE_SIZE), 1) * CALLER_LOG_PAGE_SIZE

  const refetchLoadedWindow = () =>
    logsQuery.refetch({ cursor: null, pageSize: loadedPageSize() }).catch(() => {})

  // The cursors encode offsets, so a row missing from the middle of the list would make the
  //   next page skip one; while further pages exist, the loaded window is read again instead.
  const removeLog = (connection: Connection, removeLogId: string): Connection | undefined => {
    const edges = connection.edges.filter((edge) => edge.node.id !== removeLogId)

    if (edges.length === connection.edges.length) return undefined

    if (connection.pageInfo.hasNextPage) {
      refetchLoadedWindow()
      return undefined
    }

    nextTick(() => {
      getApolloClient().cache.gc()
    })

    return {
      ...connection,
      edges,
      totalCount: connection.totalCount - 1,
      pageInfo: { ...connection.pageInfo, endCursor: edges.at(-1)?.cursor ?? null },
    }
  }

  // Newest first, so an added call always belongs at the top; the cache policy of the
  //   connection drops it again from the next page, where the shifted offsets repeat it.
  const addLog = (
    connection: Connection,
    log: NonNullable<CtiLogUpdatesSubscription['ctiLogUpdates']['addLog']>,
  ): Connection | undefined => {
    if (connection.edges.some((edge) => edge.node.id === log.id)) return undefined

    return {
      ...connection,
      edges: [{ __typename: 'CtiLogEdge', node: log, cursor: '' }, ...connection.edges],
      totalCount: connection.totalCount + 1,
    }
  }

  logsQuery.subscribeToMore<CtiLogUpdatesSubscriptionVariables, CtiLogUpdatesSubscription>({
    document: CtiLogUpdatesDocument,
    updateQuery(previous, { subscriptionData }) {
      const updates = subscriptionData.data?.ctiLogUpdates
      const connection = previous?.ctiLogs

      // A changed call is written to the normalized cache by id, and its row re-renders itself.
      if (!updates || !connection || updates.updateLog) return previous

      let next: Connection | undefined

      if (updates.removeLogId) next = removeLog(connection, updates.removeLogId)
      else if (updates.addLog) next = addLog(connection, updates.addLog)

      return next ? { ctiLogs: next } : previous
    },
  })

  return {
    logsQuery,
    logs,
    totalCount,
    loading,
    error,
    pagination,
    fetchNextPage: () => pagination.fetchNextPage(),
  }
}
