// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { effectScope, ref } from 'vue'

import { resetPushNotificationDatabase } from '#tests/support/mock-pushNotificationDatabase.ts'

import {
  rememberShownPushNotification,
  takeVanishedPushNotifications,
} from '#shared/sw/shownPushNotifications.ts'

import { usePushNotificationClick } from '../usePushNotificationClick.ts'

// The tags of the unseen notifications, as the count subscription would deliver them.
const { unseenPushTags } = await vi.hoisted(async () => {
  const { ref: hoistedRef } = await import('vue')
  return { unseenPushTags: hoistedRef<string[]>() }
})

vi.mock('#shared/entities/online-notification/composables/useOnlineNotificationCount.ts', () => ({
  useOnlineNotificationCount: () => ({
    unseenPushTags,
    unseenCount: ref<number>(),
    notificationsCountSubscription: {},
  }),
}))

vi.mock('#shared/sw/pushNotificationDatabase.ts', async () => {
  const { pushNotificationDatabaseMock } =
    await import('#tests/support/mock-pushNotificationDatabase.ts')
  return pushNotificationDatabaseMock
})

const routerPush = vi.fn()

vi.mock('vue-router', async () => ({
  ...(await vi.importActual<typeof import('vue-router')>('vue-router')),
  useRouter: () => ({ push: routerPush }),
}))

describe('usePushNotificationClick', () => {
  const displayedTags: string[] = []
  const closed: string[] = []
  const getNotifications = vi.fn(async () =>
    [...displayedTags].map((tag) => ({
      tag,
      close: () => {
        closed.push(tag)
        displayedTags.splice(displayedTags.indexOf(tag), 1)
      },
    })),
  )
  let subscribed: boolean
  let scope: ReturnType<typeof effectScope>

  const showApp = async () => {
    Object.defineProperty(document, 'visibilityState', { value: 'visible', configurable: true })
    document.dispatchEvent(new Event('visibilitychange'))

    await vi.waitFor(() => expect(getNotifications).toHaveBeenCalled())
    await new Promise((resolve) => setTimeout(resolve))
  }

  beforeEach(() => {
    routerPush.mockClear()
    getNotifications.mockClear()
    displayedTags.length = 0
    closed.length = 0
    unseenPushTags.value = undefined
    subscribed = true
    resetPushNotificationDatabase()

    Object.defineProperty(window, 'Notification', {
      value: { permission: 'granted' },
      configurable: true,
    })
    Object.defineProperty(window, 'PushManager', { value: class {}, configurable: true })
    Object.defineProperty(navigator, 'serviceWorker', {
      value: {
        getRegistration: vi.fn(async () => ({
          getNotifications,
          pushManager: { getSubscription: async () => (subscribed ? {} : null) },
        })),
        addEventListener: vi.fn(),
        startMessages: vi.fn(),
      },
      configurable: true,
    })

    scope = effectScope()
    scope.run(() => usePushNotificationClick())
  })

  afterEach(() => {
    scope.stop()
    Reflect.deleteProperty(navigator, 'serviceWorker')
    Reflect.deleteProperty(window, 'Notification')
    Reflect.deleteProperty(window, 'PushManager')
  })

  it('opens the page of a push the service worker reports as tapped', () => {
    const [[, onMessage]] = vi.mocked(navigator.serviceWorker.addEventListener).mock.calls

    ;(onMessage as (event: MessageEvent) => void)(
      new MessageEvent('message', {
        data: { type: 'PUSH_NOTIFICATION_CLICK', path: '/tickets/42' },
      }),
    )

    expect(routerPush).toHaveBeenCalledExactlyOnceWith('/tickets/42')
  })

  it('opens the push that was tapped while the app was in the background', async () => {
    await rememberShownPushNotification({
      tag: 'ticket-42',
      path: '/tickets/42',
      shownAt: Date.now(),
    })
    await rememberShownPushNotification({
      tag: 'ticket-7',
      path: '/tickets/7',
      shownAt: Date.now(),
    })
    displayedTags.push('ticket-7')

    await showApp()

    expect(routerPush).toHaveBeenCalledExactlyOnceWith('/tickets/42')
  })

  it('takes no push for tapped that vanished while notifications were turned off in the settings', async () => {
    await rememberShownPushNotification({
      tag: 'ticket-42',
      path: '/tickets/42',
      shownAt: Date.now(),
    })
    displayedTags.push('ticket-42')

    await showApp()

    Object.defineProperty(window, 'Notification', {
      value: { permission: 'default' },
      configurable: true,
    })
    displayedTags.length = 0
    document.dispatchEvent(new Event('visibilitychange'))
    await new Promise((resolve) => setTimeout(resolve))

    Object.defineProperty(window, 'Notification', {
      value: { permission: 'granted' },
      configurable: true,
    })
    getNotifications.mockClear()

    await showApp()

    expect(routerPush).not.toHaveBeenCalled()
  })

  it('checks only once when the app gets visible and focused at the same time', async () => {
    await rememberShownPushNotification({
      tag: 'ticket-42',
      path: '/tickets/42',
      shownAt: Date.now(),
    })

    window.dispatchEvent(new Event('focus'))
    await showApp()

    expect(getNotifications).toHaveBeenCalledOnce()
    expect(routerPush).toHaveBeenCalledExactlyOnceWith('/tickets/42')
  })

  it('does not navigate when several pushes were removed, as cleaning up does', async () => {
    await rememberShownPushNotification({
      tag: 'ticket-42',
      path: '/tickets/42',
      shownAt: Date.now(),
    })
    await rememberShownPushNotification({
      tag: 'ticket-7',
      path: '/tickets/7',
      shownAt: Date.now(),
    })

    await showApp()

    expect(routerPush).not.toHaveBeenCalled()
  })

  it('counts pushes displayed at the last check when telling a tap from cleaning up', async () => {
    displayedTags.push('ticket-1', 'ticket-2')
    await showApp()

    await rememberShownPushNotification({
      tag: 'ticket-42',
      path: '/tickets/42',
      shownAt: Date.now(),
    })
    displayedTags.length = 0
    getNotifications.mockClear()
    await showApp()

    expect(routerPush).not.toHaveBeenCalled()
  })

  it('does not look for a tapped push while push is off on this device', async () => {
    subscribed = false
    await rememberShownPushNotification({
      tag: 'ticket-42',
      path: '/tickets/42',
      shownAt: Date.now(),
    })

    Object.defineProperty(document, 'visibilityState', { value: 'visible', configurable: true })
    document.dispatchEvent(new Event('visibilitychange'))
    await new Promise((resolve) => setTimeout(resolve))

    expect(getNotifications).not.toHaveBeenCalled()
    expect(routerPush).not.toHaveBeenCalled()
  })

  it('stays on the current page while every push is still displayed', async () => {
    await rememberShownPushNotification({
      tag: 'ticket-42',
      path: '/tickets/42',
      shownAt: Date.now(),
    })
    displayedTags.push('ticket-42')

    await showApp()

    expect(routerPush).not.toHaveBeenCalled()
  })

  describe('pushes seen elsewhere', () => {
    const remember = (tag: string) =>
      rememberShownPushNotification({ tag, path: `/${tag}`, shownAt: Date.now() })

    it('closes the pushes whose notifications were seen when the app comes to the front', async () => {
      await remember('ticket-42')
      await remember('ticket-7')
      displayedTags.push('ticket-42', 'ticket-7')
      unseenPushTags.value = ['ticket-42']

      await showApp()

      expect(closed).toEqual(['ticket-7'])
      expect(displayedTags).toEqual(['ticket-42'])
      expect(routerPush).not.toHaveBeenCalled()
    })

    it('closes them when the unseen notifications change while the app runs', async () => {
      await remember('ticket-42')
      displayedTags.push('ticket-42')
      unseenPushTags.value = ['ticket-42']

      await showApp()
      expect(closed).toEqual([])

      unseenPushTags.value = []
      await vi.waitFor(() => expect(closed).toEqual(['ticket-42']))
    })

    it('does not take a push it closed itself for tapped afterwards', async () => {
      await remember('ticket-7')
      displayedTags.push('ticket-7')
      unseenPushTags.value = []

      await showApp()
      expect(closed).toEqual(['ticket-7'])

      getNotifications.mockClear()
      await showApp()

      expect(routerPush).not.toHaveBeenCalled()
      expect(await takeVanishedPushNotifications([])).toEqual([])
    })

    it('closes nothing while the unseen notifications are not known yet', async () => {
      displayedTags.push('ticket-7')

      await showApp()

      expect(closed).toEqual([])
    })
  })
})
