// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isEmpty } from 'lodash-es'
import { computed, onBeforeUnmount, type Ref, ref } from 'vue'
import { useRoute } from 'vue-router'

import type { MacroById } from '#shared/entities/macro/types.ts'
import { useMacrosQuery } from '#shared/graphql/queries/macros.api.ts'
import { EnumTicketScreenBehavior, type TicketMacrosSelectorInput } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { useMacroStore } from '#shared/stores/macro.ts'

export const macroScreenBehaviourMapping: Record<string, EnumTicketScreenBehavior> = {
  next_task: EnumTicketScreenBehavior.CloseTab,
  next_from_overview: EnumTicketScreenBehavior.CloseNextInOverview,
  next_task_on_close: EnumTicketScreenBehavior.CloseTabOnTicketClose,
  none: EnumTicketScreenBehavior.StayOnTab,
}

export const useMacros = (selector: Ref<TicketMacrosSelectorInput>) => {
  const macroQuery = new QueryHandler(
    useMacrosQuery(
      () => ({
        selector: selector.value,
      }),
      () => ({ enabled: !isEmpty(selector.value) }),
    ),
  )

  const { activate, deactivate } = useMacroStore()

  const route = useRoute()

  // TODO: Drop this mechanism once Apollo implements an effective deduplication of subscriptions on the client level.
  //   More information: https://github.com/apollographql/apollo-client/issues/10117
  const usageKey = route.meta.taskbarTabEntityKey ?? 'apply-macro'

  activate(usageKey, macroQuery)

  onBeforeUnmount(() => {
    deactivate(usageKey)
  })

  const result = macroQuery.result()

  const macrosLoaded = ref(false)

  macroQuery.watchOnResult(() => {
    macrosLoaded.value = true
  })

  const translatedMacros = computed(
    () =>
      result.value?.macros.map((macro) => Object.assign({}, macro, { name: i18n.t(macro.name) })) ??
      [],
  )

  const macros = computed(() =>
    translatedMacros.value.sort((a, b) =>
      a.name.localeCompare(b.name, i18n.locale.name, { numeric: true, sensitivity: 'base' }),
    ),
  )

  return { macrosLoaded, macros }
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
