// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { QueryHandler } from '@common/server/apollo/handler'
import { computed, reactive, readonly } from 'vue'
import {
  BaseConnection,
  OperationQueryResult,
  PaginationVariables,
} from '@common/types/server/apollo/handler'
import { OperationVariables } from '@apollo/client/core'

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

  return reactive({
    pageInfo: readonly(pageInfo),
    hasNextPage: readonly(hasNextPage),
    fetchNextPage() {
      query.fetchMore({
        variables: {
          cursor: pageInfo.value?.endCursor,
        } as Partial<TQueryVariables & PaginationVariables>,
      })
    },
  })
}
