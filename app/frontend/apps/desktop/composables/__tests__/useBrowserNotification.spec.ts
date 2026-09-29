// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineComponent, h } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { resetGlobalStates } from '#tests/support/mock-globalState.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import {
  holdLockFromAnotherTab,
  mockWebLocks,
  unmockWebLocks,
} from '#tests/support/mock-webLocks.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { useSessionStore } from '#shared/stores/session.ts'

import {
  BROWSER_NOTIFICATION_LOCK,
  useBrowserNotification,
  useBrowserNotificationPermissionRequest,
  useBrowserNotificationTab,
} from '../useBrowserNotification.ts'

// The shared instance snapshots the permission when it is created, so every
//   example gets a fresh one that is still shared within the example.
vi.mock('@vueuse/core', async (importOriginal) => ({
  ...(await importOriginal<typeof import('@vueuse/core')>()),
  createGlobalState: (await import('#tests/support/mock-globalState.ts')).createGlobalState,
}))

// Lives in the app root, so a component hosts it here.
const Host = defineComponent({
  setup() {
    useBrowserNotificationPermissionRequest()

    return () => h('div')
  },
})

const requestPermissionSpy = vi.fn(() => Promise.resolve('granted'))

const mockNotificationPermission = (permission: NotificationPermission) =>
  Object.assign(Notification, { permission, requestPermission: requestPermissionSpy })

const startSession = (permissions: string[], initialized = true) => {
  mockPermissions(permissions)

  const session = useSessionStore()
  session.initialized = initialized

  return renderComponent(Host)
}

const interact = async () => {
  window.dispatchEvent(new Event('pointerup'))
  await waitForNextTick()
}

describe('useBrowserNotificationPermissionRequest', () => {
  beforeEach(() => {
    resetGlobalStates()
    mockNotificationPermission('default')
  })

  afterEach(() => {
    Object.assign(Notification, {
      permission: 'granted',
      requestPermission: () => Promise.resolve('granted'),
    })
  })

  it('asks a ticket agent after the first interaction', async () => {
    startSession(['ticket.agent'])

    await waitForNextTick()

    expect(requestPermissionSpy).not.toHaveBeenCalled()
    expect(useBrowserNotification().permissionGranted.value).toBe(false)

    await interact()

    expect(requestPermissionSpy).toHaveBeenCalledOnce()
    expect(useBrowserNotification().permissionGranted.value).toBe(true)
  })

  it('asks a phone-only agent after the first key press', async () => {
    startSession(['cti.agent'])

    window.dispatchEvent(new Event('keydown'))
    await waitForNextTick()

    expect(requestPermissionSpy).toHaveBeenCalledOnce()
  })

  it.each(['Escape', 'Shift', 'Control', 'Alt', 'Meta'])(
    'does not spend the request on a %s key press',
    async (key) => {
      startSession(['ticket.agent'])

      window.dispatchEvent(new KeyboardEvent('keydown', { key }))
      await waitForNextTick()

      expect(requestPermissionSpy).not.toHaveBeenCalled()

      await interact()

      expect(requestPermissionSpy).toHaveBeenCalledOnce()
    },
  )

  it('leaves it to a browser telling activating gestures apart', async () => {
    const userActivation = { isActive: false, hasBeenActive: false }

    Object.defineProperty(navigator, 'userActivation', {
      value: userActivation,
      configurable: true,
    })

    try {
      startSession(['ticket.agent'])

      await interact()

      expect(requestPermissionSpy).not.toHaveBeenCalled()

      userActivation.isActive = true

      await interact()

      expect(requestPermissionSpy).toHaveBeenCalledOnce()
    } finally {
      // @ts-expect-error restoring the browser without the API
      delete navigator.userActivation
    }
  })

  it('does not ask a user without an entitled permission', async () => {
    startSession(['ticket.customer'])

    await interact()

    expect(requestPermissionSpy).not.toHaveBeenCalled()
  })

  it.each(['granted', 'denied'] as const)(
    'does not ask when the permission is %s',
    async (permission) => {
      mockNotificationPermission(permission)

      startSession(['ticket.agent'])

      await interact()

      expect(requestPermissionSpy).not.toHaveBeenCalled()
    },
  )

  it('does not ask when the browser does not support notifications', async () => {
    const original = window.Notification

    // @ts-expect-error simulating a browser without the API
    delete window.Notification

    try {
      startSession(['ticket.agent'])

      await interact()

      expect(requestPermissionSpy).not.toHaveBeenCalled()
    } finally {
      Object.defineProperty(window, 'Notification', {
        value: original,
        writable: true,
        configurable: true,
      })
    }
  })

  it('asks at most once per session', async () => {
    startSession(['ticket.agent'])

    await interact()
    await interact()

    window.dispatchEvent(new Event('keydown'))
    await waitForNextTick()

    expect(requestPermissionSpy).toHaveBeenCalledOnce()
  })

  it('does not ask before the session is initialized', async () => {
    startSession(['ticket.agent'], false)

    await interact()

    expect(requestPermissionSpy).not.toHaveBeenCalled()
  })
})

describe('useBrowserNotificationTab', () => {
  beforeEach(() => {
    resetGlobalStates()
    mockWebLocks()
    vi.spyOn(document, 'hasFocus').mockReturnValue(false)
  })

  afterEach(() => {
    unmockWebLocks()
  })

  it('shows the notifications as the only tab', async () => {
    const { isNotifyingTab } = useBrowserNotificationTab()

    await waitForNextTick(true)

    expect(isNotifyingTab.value).toBe(true)
  })

  it('waits its turn behind the tab that shows them', async () => {
    const otherTab = holdLockFromAnotherTab(BROWSER_NOTIFICATION_LOCK)

    const { isNotifyingTab } = useBrowserNotificationTab()

    await waitForNextTick(true)

    expect(isNotifyingTab.value).toBe(false)

    // The other tab is closed.
    otherTab.release()
    await waitForNextTick(true)

    expect(isNotifyingTab.value).toBe(true)
  })

  it('takes over when it is in front from the start', async () => {
    vi.spyOn(document, 'hasFocus').mockReturnValue(true)

    const otherTab = holdLockFromAnotherTab(BROWSER_NOTIFICATION_LOCK)

    const { isNotifyingTab } = useBrowserNotificationTab()

    await waitForNextTick(true)

    expect(isNotifyingTab.value).toBe(true)
    expect(otherTab.lost).toHaveBeenCalledOnce()
  })

  it('takes over when the window gets focus', async () => {
    const otherTab = holdLockFromAnotherTab(BROWSER_NOTIFICATION_LOCK)

    const { isNotifyingTab } = useBrowserNotificationTab()

    await waitForNextTick(true)

    window.dispatchEvent(new Event('focus'))
    await waitForNextTick(true)

    expect(isNotifyingTab.value).toBe(true)
    expect(otherTab.lost).toHaveBeenCalledOnce()
  })

  it('hands over to the tab that got focus and is next in line', async () => {
    const { isNotifyingTab } = useBrowserNotificationTab()

    await waitForNextTick(true)

    const otherTab = holdLockFromAnotherTab(BROWSER_NOTIFICATION_LOCK, true)

    await waitForNextTick(true)

    expect(isNotifyingTab.value).toBe(false)

    otherTab.release()
    await waitForNextTick(true)

    expect(isNotifyingTab.value).toBe(true)
  })

  it('shows the notifications in a browser without the Web Locks API', () => {
    unmockWebLocks()

    expect(useBrowserNotificationTab().isNotifyingTab.value).toBe(true)
  })
})
