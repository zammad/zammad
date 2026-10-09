// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useEventListener } from '@vueuse/core'
import { watch } from 'vue'

import {
  forgetShownPushNotification,
  takeVanishedPushNotifications,
} from '#shared/sw/shownPushNotifications.ts'
import { isPushSupported } from '#shared/utils/webPush.ts'

import { getServiceWorkerRegistration } from '#mobile/sw/registration.ts'

import type { Ref } from 'vue'

// Finds the push that was tapped to bring the app back to the front, where the
//   platform does not report the tap (iOS), see shownPushNotifications.ts.
//   Also closes the pushes whose notifications were seen elsewhere, as no
//   platform lets the server do that: the tags of the unseen ones come live
//   from the server, every other push on the device is stale.
export const useTappedPushNotification = (
  onTap: (path: string) => void,
  unseenPushTags: Ref<string[] | undefined>,
) => {
  // Pushes in the notification center at the last check, to tell a tap from
  //   cleaning up: a tap removes exactly one push, cleaning up usually several.
  let lastDisplayedTags = new Set<string>()

  // Turning notifications off in the settings of the device clears the
  //   notification center, which must not look like a tap once they are back.
  let wasPermissionWithdrawn = false

  const findTappedNotification = async () => {
    if (document.visibilityState !== 'visible') return

    if (!isPushSupported()) return

    if (Notification.permission !== 'granted') {
      wasPermissionWithdrawn = true
      return
    }

    const registration = await getServiceWorkerRegistration()
    if (!registration?.getNotifications) return

    // Without push on this device there is nothing to look for, and no database to open.
    if (!(await registration.pushManager.getSubscription())) return

    const displayedTags = (await registration.getNotifications()).map(
      (notification) => notification.tag,
    )
    const vanished = await takeVanishedPushNotifications(displayedTags)

    const vanishedTags = new Set([
      ...[...lastDisplayedTags].filter((tag) => !displayedTags.includes(tag)),
      ...vanished.map((entry) => entry.tag),
    ])
    lastDisplayedTags = new Set(displayedTags)

    if (wasPermissionWithdrawn) {
      wasPermissionWithdrawn = false
      return
    }

    if (vanished.length && vanishedTags.size === 1) onTap(vanished[0].path)
  }

  // Closed pushes leave the tap detection too, or the next check would read
  //   them as tapped. Unknown tags (no answer from the server yet) close nothing.
  const closeSeenNotifications = async () => {
    const unseen = unseenPushTags.value
    if (!unseen) return

    if (!isPushSupported() || Notification.permission !== 'granted') return

    const registration = await getServiceWorkerRegistration()
    if (!registration?.getNotifications) return
    if (!(await registration.pushManager.getSubscription())) return

    const stale = (await registration.getNotifications()).filter(
      (notification) => notification.tag && !unseen.includes(notification.tag),
    )
    if (!stale.length) return

    stale.forEach((notification) => notification.close())

    const staleTags = [...new Set(stale.map((notification) => notification.tag))]
    staleTags.forEach((tag) => lastDisplayedTags.delete(tag))
    await Promise.all(staleTags.map((tag) => forgetShownPushNotification(tag)))
  }

  let pendingCheck: Promise<void> | null = null

  // iOS does not always send both events when the app comes back, and sends
  //   them together when it does, so one check runs for all of them.
  const checkTappedNotification = () => {
    pendingCheck ??= findTappedNotification()
      .then(closeSeenNotifications)
      .catch(console.error)
      .finally(() => {
        pendingCheck = null
      })
  }

  useEventListener(document, 'visibilitychange', checkTappedNotification)
  useEventListener(window, 'focus', checkTappedNotification)

  // Seen elsewhere while the app runs, e.g. on the desktop.
  watch(unseenPushTags, () => {
    closeSeenNotifications().catch(console.error)
  })
}
