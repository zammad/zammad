// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { without } from 'lodash-es'
import { defineStore } from 'pinia'
import { computed, nextTick, ref, toValue } from 'vue'

import { useMacrosUpdateSubscription } from '#shared/graphql/subscriptions/macrosUpdate.api.ts'
import type {
  MacrosQuery,
  MacrosQueryVariables,
} from '#shared/graphql/types.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'

export const useMacroStore = defineStore('macro', () => {
  const usageKeys = ref<string[]>([])

  const queryByUsageKey = new Map<
    string,
    QueryHandler<MacrosQuery, MacrosQueryVariables>
  >()

  const activate = (
    usageKey: string,
    query: QueryHandler<MacrosQuery, MacrosQueryVariables>,
  ) => {
    usageKeys.value.push(usageKey)
    queryByUsageKey.set(usageKey, query)
  }

  const enabled = computed(() => usageKeys.value.length > 0)

  const macroSubscription = new SubscriptionHandler(
    useMacrosUpdateSubscription(() => ({ enabled })),
  )

  macroSubscription.onResult((data) => {
    const macroId = data.data?.macrosUpdate.macroId
    const groupIds = data.data?.macrosUpdate.groupIds
    const removeMacroId = data.data?.macrosUpdate.removeMacroId

    if (!macroId && !removeMacroId) return

    const refetchFor: Set<ID | ID[]> = new Set()

    queryByUsageKey.forEach((query) => {
      const macros = query.operationResult.result.value?.macros

      if (
        !macros ||
        (removeMacroId && !macros.find((macro) => macro.id === removeMacroId))
      )
        return

      const { groupIds: inputGroupIds } =
        toValue(query.operationResult.variables) ?? {}

      // Skip refetching of duplicate queries with the same group ID.
      if (!inputGroupIds || refetchFor.has(inputGroupIds)) return

      if (
        groupIds &&
        groupIds.length &&
        !groupIds.some((id) =>
          Array.isArray(inputGroupIds)
            ? inputGroupIds.includes(id)
            : inputGroupIds === id,
        ) &&
        !macros.find((macro) => macro.id === macroId)
      )
        return

      query.refetch()

      refetchFor.add(inputGroupIds)
    })
  })

  const deactivate = (usageKey: string) => {
    if (!usageKeys.value.includes(usageKey)) return

    nextTick(() => {
      usageKeys.value = without(usageKeys.value, usageKey)
      queryByUsageKey.delete(usageKey)
    })
  }

  return {
    usageKeys,
    activate,
    deactivate,
  }
})
