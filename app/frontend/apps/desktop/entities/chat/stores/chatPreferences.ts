// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { acceptHMRUpdate, defineStore, storeToRefs } from 'pinia'
import { computed } from 'vue'

import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import { useChatPreferencesQuery } from '#desktop/entities/chat/graphql/queries/chatPreferences.api.ts'

import { useChatAgentStore } from './chatAgent.ts'

// The default of the old interface, until the agent chose a limit.
const DEFAULT_MAX_WINDOWS = 4

// The agent's own chat settings. A store, so the page, its toolbar and the settings read the same
//   preferences from one query.
export const useChatPreferencesStore = defineStore('chatPreferences', () => {
  const { isEnabled, ownRunningSessions } = storeToRefs(useChatAgentStore())

  const preferencesQuery = new QueryHandler(
    useChatPreferencesQuery({
      enabled: isEnabled,
      fetchPolicy: 'cache-and-network',
    }),
    {
      // The limit is a guard, not a reason to interrupt the agent.
      errorShowNotification: false,
    },
  )

  const preferencesResult = preferencesQuery.result()

  const preferences = computed(() =>
    isEnabled.value ? preferencesResult.value?.chatPreferences : undefined,
  )

  const maxWindows = computed(() => preferences.value?.maxWindows ?? DEFAULT_MAX_WINDOWS)

  // The limit is the agent's own preference, not the number of seats of the topics.
  const isLimitReached = computed(() => ownRunningSessions.value.length >= maxWindows.value)

  // Nobody is denied before the answer is there.
  const hasTicketCreateAccess = computed(() => preferences.value?.hasTicketCreateAccess ?? true)

  const refetch = () => preferencesQuery.refetch()

  return {
    preferences,
    isLimitReached,
    hasTicketCreateAccess,
    refetch,
  }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useChatPreferencesStore, import.meta.hot))
}
