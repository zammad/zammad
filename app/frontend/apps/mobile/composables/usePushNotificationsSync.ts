// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useEventListener } from '@vueuse/core'
import { watch } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

import { usePushNotificationsStore } from '#mobile/entities/user/current/stores/pushNotifications.ts'

// Keeps the push subscription of this device registered for the current user.
export const usePushNotificationsSync = () => {
  const session = useSessionStore()
  const pushNotifications = usePushNotificationsStore()

  // The user, and with it the permissions, is loaded after the authenticated
  //   flag flips, so the user id is what has to be watched.
  watch(
    () => session.user?.id,
    (userId) => {
      if (userId) pushNotifications.sync().catch(console.error)
    },
    { immediate: true },
  )

  // Notifications may have been turned off or on in the settings of the device meanwhile.
  useEventListener(document, 'visibilitychange', () => {
    if (document.visibilityState === 'visible' && session.user?.id)
      pushNotifications.refresh().catch(console.error)
  })
}
