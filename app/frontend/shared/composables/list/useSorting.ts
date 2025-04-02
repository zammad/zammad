// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { isRef, ref, toValue, watch, type ComputedRef, type Ref } from 'vue'
import { onBeforeRouteUpdate } from 'vue-router'

import { EnumOrderDirection } from '#shared/graphql/types.ts'
import type { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import type { OperationQueryResult } from '#shared/types/server/apollo/handler.ts'

import type { OperationVariables } from '@apollo/client/core'

export const useSorting = <
  TQueryResult extends OperationQueryResult = OperationQueryResult,
  TQueryVariables extends OperationVariables = OperationVariables & {
    orderBy: string
    orderDirection: EnumOrderDirection
  },
>(
  query: QueryHandler<TQueryResult, TQueryVariables>,
  orderByParam:
    | string
    | Ref<string | undefined>
    | ComputedRef<string | undefined>
    | undefined,
  orderDirectionParam:
    | EnumOrderDirection
    | Ref<EnumOrderDirection | undefined>
    | ComputedRef<EnumOrderDirection | undefined>
    | undefined,
  scrollContainer?: Ref<HTMLElement | null>,
) => {
  // Local refs that you'll work with inside this composable
  const orderBy = ref<string | undefined>(toValue(orderByParam))
  const orderDirection = ref<EnumOrderDirection | undefined>(
    toValue(orderDirectionParam),
  )

  if (isRef(orderByParam)) {
    watch(orderByParam, (newValue) => {
      orderBy.value = newValue
    })
  }

  if (isRef(orderDirectionParam)) {
    watch(orderDirectionParam, (newValue) => {
      orderDirection.value = newValue
    })
  }

  const isSorting = ref(false)
  const sort = (
    column: string,
    direction: EnumOrderDirection,
    additionalVariables: Partial<TQueryVariables> = {},
  ) => {
    isSorting.value = true
    // It's fine to parse only partial variables, in this case the original variables values are used for
    // not given variables.
    query
      .refetch({
        orderBy: column,
        orderDirection: direction,
        ...additionalVariables,
      })
      .finally(() => {
        isSorting.value = false

        requestAnimationFrame(() => {
          scrollContainer?.value?.scrollTo({ top: 0 })
        })
      })

    orderBy.value = column
    orderDirection.value = direction
  }

  onBeforeRouteUpdate(() => {
    const newOrderBy = toValue(orderByParam)
    const newOrderDirection = toValue(orderDirectionParam)

    if (newOrderBy !== orderBy.value) {
      orderBy.value = newOrderBy
    }

    if (newOrderDirection !== orderDirection.value) {
      orderDirection.value = newOrderDirection
    }
  })

  return {
    sort,
    isSorting,
    orderBy,
    orderDirection,
  }
}
