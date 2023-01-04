// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { computed, reactive, readonly, ref } from 'vue'
import type { OperationVariables } from '@apollo/client/core'
import type { QueryHandler } from '@shared/server/apollo/handler'
import type {
  BaseConnection,
  OperationQueryResult,
  PaginationVariables,
} from '@shared/types/server/apollo/handler'

export default function usePagination<
  TQueryResult = OperationQueryResult,
  TQueryVariables = OperationVariables,
>(query: QueryHandler<TQueryResult, TQueryVariables>, resultKey: string) {
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

  const loadingNewPage = ref(false)

  return reactive({
    pageInfo: readonly(pageInfo),
    hasNextPage: readonly(hasNextPage),
    hasPreviousPage: readonly(hasPreviousPage),
    loadingNewPage: readonly(loadingNewPage),
    async fetchPreviousPage() {
      try {
        loadingNewPage.value = true
        await query.fetchMore({
          variables: {
            cursor: pageInfo.value?.startCursor,
          } as Partial<TQueryVariables & PaginationVariables>,
        })
      } finally {
        loadingNewPage.value = false
      }
    },
    async fetchNextPage() {
      try {
        loadingNewPage.value = true
        await query.fetchMore({
          variables: {
            cursor: pageInfo.value?.endCursor,
          } as Partial<TQueryVariables & PaginationVariables>,
        })
      } finally {
        loadingNewPage.value = false
      }
    },
  })
}
