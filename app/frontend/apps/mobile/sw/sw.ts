// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { clientsClaim } from 'workbox-core'
import { cleanupOutdatedCaches, precacheAndRoute } from 'workbox-precaching'

import {
  forgetShownPushNotification,
  rememberShownPushNotification,
} from '#shared/sw/shownPushNotifications.ts'
import type { PushNotificationClickMessage, PushNotificationPayload } from '#shared/sw/types.ts'

declare let self: ServiceWorkerGlobalScope

self.skipWaiting()
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') self.skipWaiting()
})

clientsClaim()
cleanupOutdatedCaches()

if (import.meta.env.MODE !== 'development') {
  precacheAndRoute(
    self.__WB_MANIFEST.map((entry) => {
      const base = import.meta.env.VITE_RUBY_PUBLIC_OUTPUT_DIR
      // this is relative to service worker script, which is
      // located in /mobile/sw.js
      // assets are loaded as /vite/assets/...
      // in the future we will probably have service worker in root
      if (typeof entry === 'string') return `../${base}/${entry}`
      return { ...entry, url: `../${base}/${entry.url}` }
    }),
  )
}

if (import.meta.env.MODE === 'development') {
  console.groupCollapsed("Service worker doesn't precache in development mode")
  self.__WB_MANIFEST.forEach((entry) => console.log(typeof entry === 'string' ? entry : entry.url))
  console.groupEnd()
  precacheAndRoute([])
}

// A path the app cannot route, e.g. `//host/x`, opens the start page instead.
const isAppPath = (path: unknown): path is string =>
  typeof path === 'string' && /^\/(?!\/)/.test(path)

const parsePushPayload = (event: PushEvent): PushNotificationPayload | null => {
  if (!event.data) return null

  try {
    const payload = event.data.json() as Partial<PushNotificationPayload>
    if (!payload.title || !payload.body) return null

    return {
      ...payload,
      path: isAppPath(payload.path) ? payload.path : '/',
    } as PushNotificationPayload
  } catch {
    return null
  }
}

interface NotificationData {
  path: string
  // Tells the push just shown from the older ones of the same tag.
  id: string
}

// Other platforms replace a push by its tag, iOS ignores the tag and stacks
//   them, so the other pushes about the same ticket are closed by hand. iOS
//   drops a close for a notification whose worker instance is still around,
//   about half a minute after showing, so pushes that arrive in a burst stay
//   until a tap closes them.
const closeNotifications = async (tag: string, except?: string) => {
  const displayed = await self.registration.getNotifications({ tag })

  displayed
    .filter(
      (notification) =>
        except === undefined || (notification.data as NotificationData | undefined)?.id !== except,
    )
    .forEach((notification) => notification.close())
}

const isDisplayed = async (tag: string) =>
  (await self.registration.getNotifications({ tag })).length > 0

// iOS revokes a subscription after a few pushes that show no notification,
// so an unreadable payload still surfaces as a generic one.
const showPush = async (event: PushEvent) => {
  const payload = parsePushPayload(event)

  const title = payload?.title ?? 'Zammad'
  const data: NotificationData = { path: payload?.path ?? '/', id: crypto.randomUUID() }
  const options: NotificationOptions = {
    body: payload?.body ?? '',
    tag: payload?.tag,
    icon: '/assets/frontend/app-icon-192.png',
    data,
  }

  await self.registration.showNotification(title, options)

  if (!options.tag) return

  // Shown first, closed after: there is a visible notification at any time.
  await closeNotifications(options.tag, data.id)
  await rememberShownPushNotification({ tag: options.tag, path: data.path, shownAt: Date.now() })
}

// Pushes that arrive together are handled one after the other, so each one
//   sees the notification the one before it has shown.
let pushQueue: Promise<void> = Promise.resolve()

self.addEventListener('push', (event) => {
  pushQueue = pushQueue.then(() => showPush(event)).catch(console.error)

  event.waitUntil(pushQueue)
})

// A push closed to make room for a newer one of the same tag is still
//   remembered, the newer one carries the tag on.
self.addEventListener('notificationclose', (event) => {
  const { tag } = event.notification
  if (!tag) return

  event.waitUntil(
    isDisplayed(tag).then((displayed) =>
      displayed ? undefined : forgetShownPushNotification(tag),
    ),
  )
})

// The list holds every window of the origin, the desktop app included, but
//   only the mobile app listens for the click message.
const isMobileWindow = (candidate: Client): candidate is WindowClient =>
  'focus' in candidate && new URL(candidate.url).pathname.startsWith('/mobile/')

const openClient = async (path: string) => {
  const clients = await self.clients.matchAll({ type: 'window', includeUncontrolled: true })
  const client = clients.find(isMobileWindow)

  if (client) {
    await client.focus()

    const message: PushNotificationClickMessage = { type: 'PUSH_NOTIFICATION_CLICK', path }
    client.postMessage(message)

    return
  }

  await self.clients.openWindow(new URL(`/mobile${path}`, self.location.origin).href)
}

// A tap opens the ticket, so the other pushes about it have served their purpose too.
self.addEventListener('notificationclick', (event) => {
  event.notification.close()

  const { tag } = event.notification
  const path = (event.notification.data as Partial<NotificationData> | undefined)?.path ?? '/'

  event.waitUntil(
    Promise.all([
      openClient(path),
      tag ? closeNotifications(tag).then(() => forgetShownPushNotification(tag)) : undefined,
    ]),
  )
})
