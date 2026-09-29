// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createGlobalState, useEventListener, useWebNotification } from '@vueuse/core'
import { tryOnScopeDispose } from '@vueuse/shared'
import { readonly, ref, watch } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

// Permissions of the features that show browser notifications.
const ENTITLED_PERMISSIONS = ['ticket.agent', 'cti.agent']

// Keys the browsers do not count as an activating gesture.
const NON_ACTIVATING_KEYS = new Set(['Escape', 'Shift', 'Control', 'Alt', 'AltGraph', 'Meta'])

// Firefox and Safari refuse the request without an activation, silently and
//   for good, so a request on a key press that does not activate would waste
//   the one-shot listener. The browser knows best; the key list is for those
//   that do not tell.
const isActivating = (event: Event) => {
  if (navigator.userActivation) return navigator.userActivation.isActive

  return !(event instanceof KeyboardEvent && NON_ACTIVATING_KEYS.has(event.key))
}

// One instance for the whole app: the granted flag is a snapshot per instance,
//   so the central request and the notifying features have to share it. VueUse
//   also closes the latest notification once the tab is looked at again.
export const useBrowserNotification = createGlobalState(() =>
  useWebNotification({ requestPermissions: false }),
)

// Asks for the browser notification permission once per session, from the app
//   root, so every user entitled to a notifying feature is asked, not only
//   those for whom a feature component happens to be mounted. Features only
//   check the permission and never ask themselves.
export const useBrowserNotificationPermissionRequest = () => {
  const session = useSessionStore()

  const { isSupported, permissionGranted, ensurePermissions } = useBrowserNotification()

  let stopListening: (() => void) | undefined

  const stop = () => {
    stopListening?.()
    stopListening = undefined
  }

  const request = (event: Event) => {
    if (!isActivating(event)) return

    stop()
    ensurePermissions()
  }

  const arm = () => {
    stop()

    if (!isSupported.value || permissionGranted.value) return
    if (!session.hasPermission(ENTITLED_PERMISSIONS)) return

    // Firefox and Safari show the prompt only in response to a user gesture,
    //   so the request waits for the first one instead of firing right away.
    //   A touch or pen activates on pointer up, unlike a mouse press.
    stopListening = useEventListener(window, ['pointerup', 'keydown'], request, {
      passive: true,
    })
  }

  watch(
    () => session.initialized,
    (initialized) => (initialized ? arm() : stop()),
    { immediate: true },
  )
}

// The lock is per origin, like the notification tag.
export const BROWSER_NOTIFICATION_LOCK = 'zammad-browser-notifications'

// Which of the tabs of this origin shows the browser notifications: the one the
//   agent used last. Every tab has its own subscriptions, so without this each
//   background tab would notify, even while the agent looks at another one.
//   A tab takes the lock over on focus; the tab that lost it closes what it
//   showed and waits its turn, so a closed tab hands over to one still open.
export const useBrowserNotificationTab = createGlobalState(() => {
  const isNotifyingTab = ref(false)

  // Without the Web Locks API every tab notifies, as before.
  if (!('locks' in navigator)) {
    isNotifyingTab.value = true

    return { isNotifyingTab: readonly(isNotifyingTab) }
  }

  let controller: AbortController | undefined

  // The request is rejected without an abort only when another tab took the lock over.
  const request = (steal: boolean) => {
    controller?.abort()

    controller = new AbortController()
    const { signal } = controller

    // The API refuses a signal on a stealing request, which is granted at once anyway.
    navigator.locks
      .request(BROWSER_NOTIFICATION_LOCK, steal ? { steal } : { signal }, () => {
        isNotifyingTab.value = true

        return new Promise((resolve) => {
          signal.addEventListener('abort', resolve, { once: true })
        })
      })
      .catch(() => {
        if (signal.aborted || !isNotifyingTab.value) return

        isNotifyingTab.value = false
        request(false)
      })
  }

  request(document.hasFocus())

  useEventListener(window, 'focus', () => {
    if (!isNotifyingTab.value) request(true)
  })

  tryOnScopeDispose(() => controller?.abort())

  return { isNotifyingTab: readonly(isNotifyingTab) }
})
