// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { resetPushNotificationDatabase } from '#tests/support/mock-pushNotificationDatabase.ts'

import {
  rememberShownPushNotification,
  takeVanishedPushNotifications,
} from '#shared/sw/shownPushNotifications.ts'

vi.mock('#shared/sw/pushNotificationDatabase.ts', async () => {
  const { pushNotificationDatabaseMock } =
    await import('#tests/support/mock-pushNotificationDatabase.ts')
  return pushNotificationDatabaseMock
})
vi.mock('workbox-core', () => ({ clientsClaim: vi.fn() }))
vi.mock('workbox-precaching', () => ({
  cleanupOutdatedCaches: vi.fn(),
  precacheAndRoute: vi.fn(),
}))

type Listener = (event: never) => void

const listeners: Record<string, Listener> = {}

// Notifications in the notification center, as the registration lists them.
const displayedNotifications: {
  tag?: string
  data?: unknown
  close: ReturnType<typeof vi.fn>
}[] = []

// A closed notification leaves the list, like in a real notification center.
const displayNotification = (tag?: string, data?: unknown) => {
  const notification = {
    tag,
    data,
    close: vi.fn(() => {
      displayedNotifications.splice(displayedNotifications.indexOf(notification), 1)
    }),
  }
  displayedNotifications.push(notification)
  return notification
}

const showNotification = vi.fn(async (_title: string, options: NotificationOptions) => {
  displayNotification(options.tag, options.data)
})
const getNotifications = vi.fn(async ({ tag }: { tag?: string } = {}) =>
  displayedNotifications.filter((notification) => !tag || notification.tag === tag),
)
const matchAll = vi.fn(async (): Promise<unknown[]> => [])
const openWindow = vi.fn(async () => null)

const workerGlobals = {
  skipWaiting: vi.fn(async () => {}),
  registration: { showNotification, getNotifications },
  clients: { matchAll, openWindow },
  __WB_MANIFEST: [],
}

const waitUntilResult = async (event: { waitUntil: ReturnType<typeof vi.fn> }) => {
  await event.waitUntil.mock.calls[0][0]
}

const dispatchPush = async (data: { json: () => unknown } | null) => {
  const event = { data, waitUntil: vi.fn() }
  ;(listeners.push as (event: unknown) => void)(event)
  await waitUntilResult(event)
}

const dispatchNotificationClick = async (data: unknown) => {
  const event = { notification: { data, close: vi.fn() }, waitUntil: vi.fn() }
  ;(listeners.notificationclick as (event: unknown) => void)(event)
  await waitUntilResult(event)

  return event.notification
}

const windowClient = (url = 'https://zammad.example.com/mobile/') => ({
  url,
  focus: vi.fn(async () => {}),
  postMessage: vi.fn(),
})

describe('mobile service worker', () => {
  beforeAll(async () => {
    Object.assign(globalThis, workerGlobals)

    vi.spyOn(self, 'addEventListener').mockImplementation((type, listener) => {
      listeners[type] = listener as Listener
    })

    await import('../sw.ts')
  })

  beforeEach(() => {
    matchAll.mockResolvedValue([])
    displayedNotifications.length = 0
    resetPushNotificationDatabase()
  })

  it('registers the worker lifecycle and push handlers', () => {
    expect(Object.keys(listeners).sort()).toEqual([
      'message',
      'notificationclick',
      'notificationclose',
      'push',
    ])
  })

  describe('push', () => {
    it('shows the notification from the payload', async () => {
      await dispatchPush({
        json: () => ({
          title: 'Updated ticket: Printer broken',
          body: 'Nicole Braun replied.',
          path: '/tickets/42',
          tag: 'online-notification-7',
        }),
      })

      expect(showNotification).toHaveBeenCalledWith('Updated ticket: Printer broken', {
        body: 'Nicole Braun replied.',
        tag: 'online-notification-7',
        icon: '/assets/frontend/app-icon-192.png',
        data: expect.objectContaining({ path: '/tickets/42' }),
      })
    })

    it.each([
      ['a protocol-relative path', '//example.com/tickets/42'],
      ['a path without leading slash', 'tickets/42'],
      ['a path that is no string', 42],
      ['no path', undefined],
    ])('opens the start page for %s', async (_description, path) => {
      await dispatchPush({
        json: () => ({
          title: 'Updated ticket: Printer broken',
          body: 'Nicole Braun replied.',
          path,
        }),
      })

      expect(showNotification).toHaveBeenCalledWith(
        'Updated ticket: Printer broken',
        expect.objectContaining({
          body: 'Nicole Braun replied.',
          data: expect.objectContaining({ path: '/' }),
        }),
      )
    })

    it('still shows a generic notification when the payload is incomplete', async () => {
      await dispatchPush({ json: () => ({ title: 'Only a title' }) })

      expect(showNotification).toHaveBeenCalledWith('Zammad', {
        body: '',
        tag: undefined,
        icon: '/assets/frontend/app-icon-192.png',
        data: expect.objectContaining({ path: '/' }),
      })
    })

    it('still shows a generic notification when the payload is not JSON', async () => {
      await dispatchPush({
        json: () => {
          throw new SyntaxError('Unexpected token')
        },
      })

      expect(showNotification).toHaveBeenCalledWith(
        'Zammad',
        expect.objectContaining({ data: expect.objectContaining({ path: '/' }) }),
      )
    })

    it('closes the older pushes about the same ticket once the new one is shown', async () => {
      const older = displayNotification('ticket-42')
      const other = displayNotification('ticket-7')

      await dispatchPush({
        json: () => ({ title: 'Zammad', body: 'Text', path: '/tickets/42', tag: 'ticket-42' }),
      })

      expect(older.close).toHaveBeenCalled()
      expect(other.close).not.toHaveBeenCalled()
      expect(displayedNotifications.filter((n) => n.tag === 'ticket-42')).toHaveLength(1)
    })

    it('leaves exactly one push per ticket when several arrive at once', async () => {
      const push = (body: string) => ({
        data: {
          json: () => ({ title: 'Zammad', body, path: '/tickets/42', tag: 'ticket-42' }),
        },
        waitUntil: vi.fn(),
      })
      const events = [push('first'), push('second'), push('third')]

      events.forEach((event) => (listeners.push as (event: unknown) => void)(event))
      await Promise.all(events.map(waitUntilResult))

      const open = displayedNotifications.filter((notification) => notification.tag === 'ticket-42')

      expect(open).toHaveLength(1)
      expect(showNotification).toHaveBeenLastCalledWith(
        'Zammad',
        expect.objectContaining({ body: 'third' }),
      )
    })

    it('still shows a generic notification when the push has no data', async () => {
      await dispatchPush(null)

      expect(showNotification).toHaveBeenCalledWith(
        'Zammad',
        expect.objectContaining({ data: expect.objectContaining({ path: '/' }) }),
      )
    })
  })

  describe('remembered pushes', () => {
    it('remembers a shown push for the app', async () => {
      await dispatchPush({
        json: () => ({ title: 'Zammad', body: 'Text', path: '/tickets/42', tag: 'ticket-42' }),
      })

      expect(await takeVanishedPushNotifications([])).toMatchObject([
        { tag: 'ticket-42', path: '/tickets/42' },
      ])
    })

    it('forgets a push once the click was handled', async () => {
      await rememberShownPushNotification({
        tag: 'ticket-42',
        path: '/tickets/42',
        shownAt: Date.now(),
      })

      const event = {
        notification: { data: { path: '/tickets/42' }, tag: 'ticket-42', close: vi.fn() },
        waitUntil: vi.fn(),
      }
      ;(listeners.notificationclick as (event: unknown) => void)(event)
      await waitUntilResult(event)

      expect(await takeVanishedPushNotifications([])).toEqual([])
    })

    it('keeps remembering a push that was closed to make room for a newer one', async () => {
      await rememberShownPushNotification({
        tag: 'ticket-42',
        path: '/tickets/42',
        shownAt: Date.now(),
      })
      displayNotification('ticket-42')

      const event = { notification: { tag: 'ticket-42' }, waitUntil: vi.fn() }
      ;(listeners.notificationclose as (event: unknown) => void)(event)
      await waitUntilResult(event)

      expect(await takeVanishedPushNotifications([])).toMatchObject([{ tag: 'ticket-42' }])
    })

    it('forgets a push that was dismissed', async () => {
      await rememberShownPushNotification({
        tag: 'ticket-42',
        path: '/tickets/42',
        shownAt: Date.now(),
      })

      const event = { notification: { tag: 'ticket-42' }, waitUntil: vi.fn() }
      ;(listeners.notificationclose as (event: unknown) => void)(event)
      await waitUntilResult(event)

      expect(await takeVanishedPushNotifications([])).toEqual([])
    })
  })

  describe('notificationclick', () => {
    it('closes the notification', async () => {
      const notification = await dispatchNotificationClick({ path: '/tickets/42' })

      expect(notification.close).toHaveBeenCalled()
    })

    it('closes the other pushes about the same ticket', async () => {
      const sibling = displayNotification('ticket-42')
      const other = displayNotification('ticket-7')

      const event = {
        notification: { data: { path: '/tickets/42' }, tag: 'ticket-42', close: vi.fn() },
        waitUntil: vi.fn(),
      }
      ;(listeners.notificationclick as (event: unknown) => void)(event)
      await waitUntilResult(event)

      expect(sibling.close).toHaveBeenCalled()
      expect(other.close).not.toHaveBeenCalled()
    })

    it('focuses an open window and hands it the path', async () => {
      const client = windowClient()
      matchAll.mockResolvedValue([client])

      await dispatchNotificationClick({ path: '/tickets/42' })

      expect(matchAll).toHaveBeenCalledWith({ type: 'window', includeUncontrolled: true })
      expect(client.focus).toHaveBeenCalled()
      expect(client.postMessage).toHaveBeenCalledWith({
        type: 'PUSH_NOTIFICATION_CLICK',
        path: '/tickets/42',
      })
      expect(openWindow).not.toHaveBeenCalled()
    })

    it('ignores a window of the desktop app and opens the mobile app instead', async () => {
      const desktop = windowClient('https://zammad.example.com/desktop/dashboard')
      matchAll.mockResolvedValue([desktop])

      await dispatchNotificationClick({ path: '/tickets/42' })

      expect(desktop.focus).not.toHaveBeenCalled()
      expect(desktop.postMessage).not.toHaveBeenCalled()
      expect(openWindow).toHaveBeenCalledWith(`${self.location.origin}/mobile/tickets/42`)
    })

    it('prefers a window of the mobile app over one of the desktop app listed before it', async () => {
      const desktop = windowClient('https://zammad.example.com/#ticket/zoom/42')
      const mobile = windowClient('https://zammad.example.com/mobile/tickets/7')
      matchAll.mockResolvedValue([desktop, mobile])

      await dispatchNotificationClick({ path: '/tickets/42' })

      expect(desktop.focus).not.toHaveBeenCalled()
      expect(mobile.focus).toHaveBeenCalled()
      expect(mobile.postMessage).toHaveBeenCalledWith(
        expect.objectContaining({ type: 'PUSH_NOTIFICATION_CLICK', path: '/tickets/42' }),
      )
    })

    it('opens the mobile app at the path when no window is open', async () => {
      await dispatchNotificationClick({ path: '/tickets/42' })

      expect(openWindow).toHaveBeenCalledWith(`${self.location.origin}/mobile/tickets/42`)
    })

    it('opens the mobile app start page when the notification carries no path', async () => {
      await dispatchNotificationClick(undefined)

      expect(openWindow).toHaveBeenCalledWith(`${self.location.origin}/mobile/`)
    })
  })
})
