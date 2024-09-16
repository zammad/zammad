// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type ComputedRef, ref } from 'vue'

import type { MacroById } from '#shared/entities/macro/types.ts'
import { useMacrosQuery } from '#shared/graphql/queries/macros.api.ts'
import { useMacrosUpdateSubscription } from '#shared/graphql/subscriptions/macrosUpdate.api.ts'
import {
  QueryHandler,
  SubscriptionHandler,
} from '#shared/server/apollo/handler/index.ts'

export const useMacros = (groupId: ComputedRef<ID | undefined>) => {
  const macroQuery = new QueryHandler(
    useMacrosQuery(
      () => ({
        groupId: groupId.value as string,
      }),
      () => ({ enabled: !!groupId.value }),
    ),
  )

  const macroSubscription = new SubscriptionHandler(
    useMacrosUpdateSubscription(() => ({
      enabled: !!groupId.value,
    })),
  )

  macroSubscription.onResult((data) => {
    if (data.data?.macrosUpdate.macroUpdated) macroQuery.refetch()
  })

  const result = macroQuery.result()

  const macros = computed(() => result.value?.macros)

  return { macros }
}

export const useTicketMacros = (formSubmit: () => void) => {
  const macroId = ref<ID>()

  const executeMacro = async (macro: MacroById) => {
    macroId.value = macro.id
    formSubmit()
  }

  const resetMacroId = () => {
    macroId.value = undefined
  }

  return { macroId, executeMacro, resetMacroId }
}
