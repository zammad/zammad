// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { effectScope, onScopeDispose, ref, watch } from 'vue'
import { useRouter } from 'vue-router'

import { useOnlineNotificationCount } from '#shared/entities/online-notification/composables/useOnlineNotificationCount.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { PushNotificationClickMessage } from '#shared/sw/types.ts'

import { useTappedPushNotification } from './useTappedPushNotification.ts'

import type { EffectScope } from 'vue'

// Opens the page a tapped notification points at, when the app is already
//   running: either the service worker reports the tap, or the app finds out
//   on its own when it comes back to the front.
export const usePushNotificationClick = () => {
  const router = useRouter()
  const session = useSessionStore()

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

  // The count subscription needs a session, and one that failed or was
  //   cancelled on logout never comes back by itself: started with the
  //   session, stopped without it, started afresh with the next one.
  const unseenPushTags = ref<string[]>()
  let countScope: EffectScope | undefined

  watch(
    () => session.initialized,
    (initialized) => {
      countScope?.stop()
      countScope = undefined
      unseenPushTags.value = undefined

      if (!initialized) return

      countScope = effectScope()
      countScope.run(() => {
        const count = useOnlineNotificationCount({ withPushTags: true })

        watch(count.unseenPushTags, (tags) => (unseenPushTags.value = tags), { immediate: true })
      })
    },
    { immediate: true },
  )

  // A scope created later, by the watcher, is no child of the owner scope.
  onScopeDispose(() => countScope?.stop())

  useTappedPushNotification((path) => router.push(path), unseenPushTags)
}
