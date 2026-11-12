// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { watch } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

import { useChatAnnouncementsStore } from '../stores/chatAnnouncements.ts'
import { useChatNotificationsStore } from '../stores/chatNotifications.ts'

// The stores that tell the agent about a waiting customer, an unanswered chat and a customer's
//   message end with the session, so each one needs its own. Its id starts them: unlike
//   `initialized`, it is also set for a session taken over from another tab.
export const useChatSessionStores = () => {
  const session = useSessionStore()

  watch(
    () => session.id,
    (id) => {
      if (!id) return

      useChatAnnouncementsStore()
      useChatNotificationsStore()
    },
    { immediate: true },
  )
}
