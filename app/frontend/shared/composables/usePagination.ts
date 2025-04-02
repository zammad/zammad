// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import {
  computed,
  reactive,
  readonly,
  ref,
  type ComputedRef,
  type Ref,
} from 'vue'

import type { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import type {
  BaseConnection,
  OperationQueryResult,
  PaginationVariables,
} from '#shared/types/server/apollo/handler.ts'

import type { OperationVariables } from '@apollo/client/core'

export const usePagination = <
  TQueryResult extends OperationQueryResult = OperationQueryResult,
  TQueryVariables extends OperationVariables = OperationVariables,
>(
  query: QueryHandler<TQueryResult, TQueryVariables>,
  resultKey: string,
  pageSize: number,
  additionalVariables?:
    | Ref<Partial<TQueryVariables>>
    | ComputedRef<Partial<TQueryVariables>>
    | (() => Partial<TQueryVariables>),
) => {
  const pageInfo = computed(() => {
    const result: OperationQueryResult = query.result().value || {}
    return (result[resultKey] as BaseConnection)?.pageInfo
  })

  const hasNextPage = computed(() => !!pageInfo.value?.hasNextPage)
  const hasPreviousPage = computed(() => !!pageInfo.value?.hasPreviousPage)

  const currentPage = computed(() => {
    const result: OperationQueryResult = query.result().value || {}
    const data = result[resultKey] as BaseConnection
    if (!data) return 1
    const currentLength = data.edges?.length || 0
    return currentLength ? Math.ceil(currentLength / pageSize) : 1
  })

  const loadingNewPage = ref(false)

  return reactive({
    pageInfo: readonly(pageInfo),
    hasNextPage: readonly(hasNextPage),
    hasPreviousPage: readonly(hasPreviousPage),
    loadingNewPage: readonly(loadingNewPage),
    currentPage,
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
        loadingNewPage.value = false
      }
    },
    async fetchNextPage() {
      try {
        loadingNewPage.value = true

        const nextAdditionalVariables =
          (typeof additionalVariables === 'function'
            ? additionalVariables()
            : additionalVariables?.value) || {}

        await query.fetchMore({
          variables: {
            pageSize,
            cursor: pageInfo.value?.endCursor,
            ...nextAdditionalVariables,
          } as Partial<TQueryVariables & PaginationVariables>,
        })
      } finally {
        loadingNewPage.value = false
      }
    },
  })
}
