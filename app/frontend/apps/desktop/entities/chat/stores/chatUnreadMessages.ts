// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { acceptHMRUpdate, defineStore } from 'pinia'
import { computed, ref } from 'vue'

// The messages of the customer the agent has not read yet, per conversation, for the navigation
//   entry that adds them to the waiting customers like the old interface. Kept by id like the
//   ticket's unread articles, so a window that opens only later still finds where they begin.
export const useChatUnreadMessagesStore = defineStore('chatUnreadMessages', () => {
  const unreadMessageIds = ref(new Map<string, Set<string>>())

  const addUnreadMessage = (sessionId: string, messageId: string) => {
    const messageIds = unreadMessageIds.value.get(sessionId)

    if (messageIds) messageIds.add(messageId)
    else unreadMessageIds.value.set(sessionId, new Set([messageId]))
  }

  const clearUnreadMessages = (sessionId: string) => {
    unreadMessageIds.value.delete(sessionId)
  }

  const total = computed(() =>
    [...unreadMessageIds.value.values()].reduce((sum, messageIds) => sum + messageIds.size, 0),
  )

  return {
    unreadMessageIds,
    addUnreadMessage,
    clearUnreadMessages,
    total,
  }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useChatUnreadMessagesStore, import.meta.hot))
}
