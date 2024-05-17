// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, reactive, readonly, ref } from 'vue'

import type { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import type {
  BaseConnection,
  OperationQueryResult,
  PaginationVariables,
} from '#shared/types/server/apollo/handler.ts'

import type { OperationVariables } from '@apollo/client/core'

export default function usePagination<
  TQueryResult extends OperationQueryResult = OperationQueryResult,
  TQueryVariables extends OperationVariables = OperationVariables,
>(
  query: QueryHandler<TQueryResult, TQueryVariables>,
  resultKey: string,
  pageSize: number,
) {
  const pageInfo = computed(() => {
    const result: OperationQueryResult = query.result().value || {}

    return (result[resultKey] as BaseConnection)?.pageInfo
  })

  const hasNextPage = computed(() => {
    return pageInfo.value?.hasNextPage ?? false
  })

  const hasPreviousPage = computed(() => {
    return pageInfo.value?.hasPreviousPage ?? false
  })

  const getInitialCurrentPage = (): number => {
    const result: OperationQueryResult = query.result().value || {}
    const data = result[resultKey] as BaseConnection
    if (!data) return 1
    const currentLength = data.edges?.length || 0
    if (!currentLength) return 1
    return Math.ceil(currentLength / pageSize)
  }

  const loadingNewPage = ref(false)
  const currentPage = ref(getInitialCurrentPage())

  return reactive({
    pageInfo: readonly(pageInfo),
    hasNextPage: readonly(hasNextPage),
    hasPreviousPage: readonly(hasPreviousPage),
    loadingNewPage: readonly(loadingNewPage),
    currentPage: readonly(currentPage),
    async fetchPreviousPage() {
      try {
        loadingNewPage.value = true
        await query.fetchMore({
          variables: {
            pageSize,
            cursor: pageInfo.value?.startCursor,
          } as Partial<TQueryVariables & PaginationVariables>,
        })
      } finally {
        currentPage.value -= 1
        loadingNewPage.value = false
      }
    },
    async fetchNextPage() {
      try {
        loadingNewPage.value = true
        await query.fetchMore({
          variables: {
            pageSize,
            cursor: pageInfo.value?.endCursor,
          } as Partial<TQueryVariables & PaginationVariables>,
        })
      } finally {
        currentPage.value += 1
        loadingNewPage.value = false
      }
    },
  })
}
