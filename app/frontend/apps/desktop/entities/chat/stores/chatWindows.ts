// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { acceptHMRUpdate, defineStore, storeToRefs } from 'pinia'
import { ref, watch } from 'vue'

import { useChatAgentStore } from './chatAgent.ts'

// The conversations the agent has open on the chat page: as in the old UI a list of windows, not a
//   route each. A session found through search joins it, and a conversation that ends stays until
//   the agent closes its window, so they can read how it ended.
export const useChatWindowsStore = defineStore('chatWindows', () => {
  const { ownRunningSessions } = storeToRefs(useChatAgentStore())

  const sessionIds = ref<string[]>([])

  const windowToReveal = ref<string>()

  // Once, however often it is chosen.
  const openWindow = (id: string) => {
    if (!sessionIds.value.includes(id)) sessionIds.value.push(id)
  }

  // Closing a window leaves the session as it is.
  const closeWindow = (id: string) => {
    sessionIds.value = sessionIds.value.filter((sessionId) => sessionId !== id)
  }

  // Every session the agent runs has a window, wherever they accepted it.
  watch(
    () => ownRunningSessions.value.map((session) => session.id),
    (runningIds) => runningIds.forEach(openWindow),
    { immediate: true },
  )

  return { sessionIds, windowToReveal, openWindow, closeWindow }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useChatWindowsStore, import.meta.hot))
}
