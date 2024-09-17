// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref, ref } from 'vue'

import type { MacroById } from '#shared/entities/macro/types.ts'
import { useMacrosQuery } from '#shared/graphql/queries/macros.api.ts'
import { useMacrosUpdateSubscription } from '#shared/graphql/subscriptions/macrosUpdate.api.ts'
import { EnumTicketScreenBehavior } from '#shared/graphql/types.ts'
import {
  QueryHandler,
  SubscriptionHandler,
} from '#shared/server/apollo/handler/index.ts'

export const macroScreenBehaviourMapping: Record<
  string,
  EnumTicketScreenBehavior
> = {
  next_task: EnumTicketScreenBehavior.CloseTab,
  next_from_overview: EnumTicketScreenBehavior.CloseNextInOverview,
  next_task_on_close: EnumTicketScreenBehavior.CloseTabOnTicketClose,
  none: EnumTicketScreenBehavior.StayOnTab,
}

export const useMacros = (groupId: Ref<ID | undefined>) => {
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
  const activeMacro = ref<MacroById>()

  const executeMacro = async (macro: MacroById) => {
    activeMacro.value = macro
    formSubmit()
  }

  const disposeActiveMacro = () => {
    activeMacro.value = undefined
  }

  return { activeMacro, executeMacro, disposeActiveMacro }
}
