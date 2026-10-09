// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createPinia, setActivePinia } from 'pinia'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { UserCurrentPushSubscriptionAddDocument } from '#shared/entities/user/current/graphql/mutations/userCurrentPushSubscriptionAdd.api.ts'
import {
  mockUserCurrentPushSubscriptionAdd,
  waitForUserCurrentPushSubscriptionAddCalls,
} from '#shared/entities/user/current/graphql/mutations/userCurrentPushSubscriptionAdd.mocks.ts'
import {
  mockUserCurrentPushSubscriptionDelete,
  waitForUserCurrentPushSubscriptionDeleteCalls,
} from '#shared/entities/user/current/graphql/mutations/userCurrentPushSubscriptionDelete.mocks.ts'

import { usePushNotificationsStore } from '../pushNotifications.ts'

vi.mock('#shared/sw/pushNotificationDatabase.ts', async () => {
  const { pushNotificationDatabaseMock } =
    await import('#tests/support/mock-pushNotificationDatabase.ts')
  return pushNotificationDatabaseMock
})

const iPhoneUserAgent =
  'Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.7 Mobile/15E148 Safari/604.1'

const subscriptionData = {
  endpoint: 'https://push.example.com/subscription/1',
  keys: { p256dh: 'client-public-key', auth: 'client-auth-secret' },
}

const mockBrowserPush = ({
  permission = 'default',
  requestedPermission = 'granted',
  subscribed = false,
}: {
  permission?: NotificationPermission
  requestedPermission?: NotificationPermission
  subscribed?: boolean
} = {}) => {
  const pushSubscription = {
    endpoint: subscriptionData.endpoint,
    toJSON: () => subscriptionData,
    unsubscribe: vi.fn(async () => true),
  }

  const pushManager = {
    getSubscription: vi.fn(async () => (subscribed ? pushSubscription : null)),
    subscribe: vi.fn(async () => pushSubscription),
  }

  const notification = {
    permission,
    requestPermission: vi.fn(async () => {
      notification.permission = requestedPermission
      return requestedPermission
    }),
  }

  Object.defineProperty(window, 'Notification', { value: notification, configurable: true })
  Object.defineProperty(window, 'PushManager', { value: class {}, configurable: true })
  Object.defineProperty(navigator, 'serviceWorker', {
    value: {
      getRegistration: vi.fn(async (): Promise<unknown> => ({ pushManager, active: {} })),
      addEventListener: vi.fn(),
      ready: Promise.resolve(),
    },
    configurable: true,
  })

  return { pushManager, pushSubscription, notification }
}

const mockSupportedEnvironment = () => {
  mockApplicationConfig({ web_push_vapid_public_key: 'QUJD' })
  mockPermissions(['user_preferences.notifications', 'ticket.agent'])
}

describe('usePushNotificationsStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    localStorage.clear()
  })

  afterEach(() => {
    Reflect.deleteProperty(window, 'Notification')
    Reflect.deleteProperty(window, 'PushManager')
    Reflect.deleteProperty(navigator, 'serviceWorker')
  })

  it('is hidden without the notifications permission', () => {
    mockBrowserPush()
    mockApplicationConfig({ web_push_vapid_public_key: 'QUJD' })
    mockPermissions(['ticket.agent'])

    expect(usePushNotificationsStore().state).toBe('hidden')
  })

  describe('when a prerequisite is missing', () => {
    afterEach(() => {
      Reflect.deleteProperty(window, 'isSecureContext')
    })

    const unavailableReason = async () => {
      const store = usePushNotificationsStore()

      await store.refresh()

      expect(store.state).toBe('unavailable')

      return store.unavailableReason
    }

    it('names a connection without HTTPS', async () => {
      mockBrowserPush()
      mockSupportedEnvironment()
      Object.defineProperty(window, 'isSecureContext', { value: false, configurable: true })

      expect(await unavailableReason()).toBe('insecure-connection')
    })

    it('names an iPhone where the app is not on the home screen', async () => {
      mockSupportedEnvironment()
      const userAgent = vi.spyOn(navigator, 'userAgent', 'get').mockReturnValue(iPhoneUserAgent)

      expect(await unavailableReason()).toBe('not-installed')

      userAgent.mockRestore()
    })

    it('names a browser without push support', async () => {
      mockSupportedEnvironment()

      expect(await unavailableReason()).toBe('unsupported-browser')
    })

    it('names a system without push keys', async () => {
      mockBrowserPush()
      mockSupportedEnvironment()
      mockApplicationConfig({ web_push_vapid_public_key: '' })

      expect(await unavailableReason()).toBe('not-configured')
    })

    it('names a missing service worker', async () => {
      mockBrowserPush()
      mockSupportedEnvironment()
      vi.mocked(navigator.serviceWorker.getRegistration).mockResolvedValue(undefined)

      expect(await unavailableReason()).toBe('service-worker-missing')
    })
  })

  it('waits for a service worker that is still installing', async () => {
    mockBrowserPush()
    mockSupportedEnvironment()

    let activate = () => {}
    const ready = new Promise<void>((resolve) => {
      activate = resolve
    })
    Object.assign(navigator.serviceWorker, { ready })
    vi.mocked(navigator.serviceWorker.getRegistration).mockResolvedValue({
      active: null,
    } as unknown as ServiceWorkerRegistration)

    const store = usePushNotificationsStore()

    await store.refresh()

    expect(store.unavailableReason).toBe('service-worker-installing')

    activate()

    await vi.waitFor(() => expect(store.unavailableReason).toBeNull())
    expect(store.state).not.toBe('unavailable')
  })

  it('is denied when the browser blocks notifications', () => {
    mockBrowserPush({ permission: 'denied' })
    mockSupportedEnvironment()

    expect(usePushNotificationsStore().state).toBe('denied')
  })

  it('subscribes this device and registers it for the user', async () => {
    const { pushManager } = mockBrowserPush()
    mockSupportedEnvironment()
    mockUserCurrentPushSubscriptionAdd({
      userCurrentPushSubscriptionAdd: { success: true, errors: null },
    })

    const store = usePushNotificationsStore()

    expect(store.state).toBe('disabled')

    await store.enable()

    expect(pushManager.subscribe).toHaveBeenCalledWith(
      expect.objectContaining({ userVisibleOnly: true }),
    )

    const calls = await waitForUserCurrentPushSubscriptionAddCalls()

    expect(calls.at(-1)?.variables).toEqual({ input: subscriptionData })
    expect(store.state).toBe('enabled')
  })

  it('reports push expired once the device lost a subscription that was turned on here', async () => {
    const { pushManager } = mockBrowserPush()
    mockSupportedEnvironment()
    mockUserCurrentPushSubscriptionAdd({
      userCurrentPushSubscriptionAdd: { success: true, errors: null },
    })

    const store = usePushNotificationsStore()

    await store.enable()

    pushManager.getSubscription.mockResolvedValue(null)
    await store.sync()

    expect(store.state).toBe('expired')

    await store.enable()

    expect(store.state).toBe('enabled')
  })

  it('is denied on an iPhone whose settings withdrew the permission after push was on', async () => {
    const { notification } = mockBrowserPush()
    mockSupportedEnvironment()
    mockUserCurrentPushSubscriptionAdd({
      userCurrentPushSubscriptionAdd: { success: true, errors: null },
    })
    Object.defineProperty(navigator, 'standalone', { value: true, configurable: true })
    const userAgent = vi.spyOn(navigator, 'userAgent', 'get').mockReturnValue(iPhoneUserAgent)

    const store = usePushNotificationsStore()

    await store.enable()

    notification.permission = 'default'
    await store.sync()

    expect(store.state).toBe('denied')

    notification.permission = 'granted'
    await store.sync()

    expect(store.state).not.toBe('denied')

    userAgent.mockRestore()
    Reflect.deleteProperty(navigator, 'standalone')
  })

  it('takes up a permission granted again in the settings, without registering the device again', async () => {
    const { notification } = mockBrowserPush({ permission: 'denied', subscribed: true })
    mockSupportedEnvironment()

    const store = usePushNotificationsStore()

    expect(store.state).toBe('denied')

    notification.permission = 'granted'
    await store.refresh()

    expect(store.state).toBe('enabled')
    expect(getGraphQLMockCalls(UserCurrentPushSubscriptionAddDocument)).toHaveLength(0)
  })

  it('stays off when the user refuses the browser permission', async () => {
    const { pushManager } = mockBrowserPush({ requestedPermission: 'denied' })
    mockSupportedEnvironment()

    const store = usePushNotificationsStore()

    await store.enable()

    expect(pushManager.subscribe).not.toHaveBeenCalled()
    expect(store.state).toBe('denied')
  })

  it('unsubscribes this device and removes it from the user', async () => {
    const { pushSubscription } = mockBrowserPush({ permission: 'granted', subscribed: true })
    mockSupportedEnvironment()
    mockUserCurrentPushSubscriptionAdd({
      userCurrentPushSubscriptionAdd: { success: true, errors: null },
    })
    mockUserCurrentPushSubscriptionDelete({
      userCurrentPushSubscriptionDelete: { success: true, errors: null },
    })

    const store = usePushNotificationsStore()

    await store.sync()

    expect(store.state).toBe('enabled')

    await store.disable()

    const calls = await waitForUserCurrentPushSubscriptionDeleteCalls()

    expect(calls.at(-1)?.variables).toEqual({ endpoint: subscriptionData.endpoint })
    expect(pushSubscription.unsubscribe).toHaveBeenCalled()
    expect(store.state).toBe('disabled')
  })

  it('does not report push expired after it was turned off', async () => {
    const { pushManager } = mockBrowserPush({ permission: 'granted', subscribed: true })
    mockSupportedEnvironment()
    mockUserCurrentPushSubscriptionAdd({
      userCurrentPushSubscriptionAdd: { success: true, errors: null },
    })
    mockUserCurrentPushSubscriptionDelete({
      userCurrentPushSubscriptionDelete: { success: true, errors: null },
    })

    const store = usePushNotificationsStore()

    await store.enable()
    await store.disable()

    pushManager.getSubscription.mockResolvedValue(null)
    await store.sync()

    expect(store.state).toBe('disabled')
  })

  it('unregisters the device on logout but keeps the browser subscription', async () => {
    const { pushSubscription } = mockBrowserPush({ permission: 'granted', subscribed: true })
    mockSupportedEnvironment()
    mockUserCurrentPushSubscriptionDelete({
      userCurrentPushSubscriptionDelete: { success: true, errors: null },
    })

    const store = usePushNotificationsStore()

    await store.unregisterDevice()

    const calls = await waitForUserCurrentPushSubscriptionDeleteCalls()

    expect(calls.at(-1)?.variables).toEqual({ endpoint: subscriptionData.endpoint })
    expect(pushSubscription.unsubscribe).not.toHaveBeenCalled()
    expect(store.state).toBe('disabled')
  })

  it('reports push expired after a new login took up the subscription of this device', async () => {
    const { pushManager } = mockBrowserPush({ permission: 'granted', subscribed: true })
    mockSupportedEnvironment()
    mockUserCurrentPushSubscriptionAdd({
      userCurrentPushSubscriptionAdd: { success: true, errors: null },
    })
    mockUserCurrentPushSubscriptionDelete({
      userCurrentPushSubscriptionDelete: { success: true, errors: null },
    })

    const store = usePushNotificationsStore()

    await store.enable()
    await store.unregisterDevice()
    await store.sync()

    expect(store.state).toBe('enabled')

    pushManager.getSubscription.mockResolvedValue(null)
    await store.sync()

    expect(store.state).toBe('expired')
  })

  describe('when the server rejects the push service of the browser', () => {
    const rejected = {
      userCurrentPushSubscriptionAdd: {
        success: null,
        errors: [{ message: 'is not an endpoint of a known push service', field: 'endpoint' }],
      },
    }

    it('locks the toggle and drops the subscription of the browser when turning push on', async () => {
      const { pushSubscription } = mockBrowserPush()
      mockSupportedEnvironment()
      mockUserCurrentPushSubscriptionAdd(rejected)

      const store = usePushNotificationsStore()

      await store.enable()

      expect(store.state).toBe('unavailable')
      expect(store.unavailableReason).toBe('push-service-rejected')
      expect(pushSubscription.unsubscribe).toHaveBeenCalled()
    })

    it('does not report push as on for a subscription found on start that is rejected', async () => {
      const { pushSubscription } = mockBrowserPush({ permission: 'granted', subscribed: true })
      mockSupportedEnvironment()
      mockUserCurrentPushSubscriptionAdd(rejected)

      const store = usePushNotificationsStore()

      await store.sync()

      expect(store.state).toBe('unavailable')
      expect(store.unavailableReason).toBe('push-service-rejected')
      expect(pushSubscription.unsubscribe).toHaveBeenCalled()
    })
  })

  it('re-registers an existing subscription on sync', async () => {
    mockBrowserPush({ permission: 'granted', subscribed: true })
    mockSupportedEnvironment()
    mockUserCurrentPushSubscriptionAdd({
      userCurrentPushSubscriptionAdd: { success: true, errors: null },
    })

    await usePushNotificationsStore().sync()

    const calls = await waitForUserCurrentPushSubscriptionAddCalls()

    expect(calls.at(-1)?.variables).toEqual({ input: subscriptionData })
  })
})
