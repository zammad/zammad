// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useRouter } from 'vue-router'

import { useOnlineNotificationCount } from '#shared/entities/online-notification/composables/useOnlineNotificationCount.ts'
import type { PushNotificationClickMessage } from '#shared/sw/types.ts'

import { useTappedPushNotification } from './useTappedPushNotification.ts'

// Opens the page a tapped notification points at, when the app is already
//   running: either the service worker reports the tap, or the app finds out
//   on its own when it comes back to the front.
export const usePushNotificationClick = () => {
  const router = useRouter()

  if (!('serviceWorker' in navigator)) return

  navigator.serviceWorker.addEventListener(
    'message',
    (event: MessageEvent<PushNotificationClickMessage | undefined>) => {
      if (event.data?.type !== 'PUSH_NOTIFICATION_CLICK') return

      router.push(event.data.path)
    },
  )

  // Messages are queued until the page opts in, a listener alone is not enough.
  navigator.serviceWorker.startMessages()

  const { unseenPushTags } = useOnlineNotificationCount()

  useTappedPushNotification((path) => router.push(path), unseenPushTags)
}
