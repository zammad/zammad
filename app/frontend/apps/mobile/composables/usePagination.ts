// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
    if (!pageInfo.value) return false

    return pageInfo.value.hasNextPage
  })

  const loadingNextPage = ref(false)

  return reactive({
    pageInfo: readonly(pageInfo),
    hasNextPage: readonly(hasNextPage),
    loadingNextPage: readonly(loadingNextPage),
    async fetchNextPage() {
      try {
        loadingNextPage.value = true
        await query.fetchMore({
          variables: {
            cursor: pageInfo.value?.endCursor,
          } as Partial<TQueryVariables & PaginationVariables>,
        })
      } finally {
        loadingNextPage.value = false
      }
    },
  })
}
