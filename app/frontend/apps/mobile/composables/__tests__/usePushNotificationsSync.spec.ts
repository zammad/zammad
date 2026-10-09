// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { effectScope } from 'vue'

import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { useSessionStore } from '#shared/stores/session.ts'

import { usePushNotificationsStore } from '#mobile/entities/user/current/stores/pushNotifications.ts'

import { usePushNotificationsSync } from '../usePushNotificationsSync.ts'

vi.mock('#mobile/entities/user/current/stores/pushNotifications.ts')

describe('usePushNotificationsSync', () => {
  const sync = vi.fn(async () => {})
  const refresh = vi.fn(async () => null)
  let scope: ReturnType<typeof effectScope>

  const showApp = () => {
    Object.defineProperty(document, 'visibilityState', { value: 'visible', configurable: true })
    document.dispatchEvent(new Event('visibilitychange'))
  }

  beforeEach(() => {
    sync.mockClear()
    refresh.mockClear()

    vi.mocked(usePushNotificationsStore).mockReturnValue({
      sync,
      refresh,
    } as unknown as ReturnType<typeof usePushNotificationsStore>)

    mockPermissions(['user_preferences.notifications', 'ticket.agent'])

    scope = effectScope()
  })

  afterEach(() => {
    scope.stop()
  })

  it('registers the device for the user who is logged in', () => {
    scope.run(() => usePushNotificationsSync())

    expect(sync).toHaveBeenCalledOnce()
  })

  it('registers the device again for the next user who logs in', async () => {
    const session = useSessionStore()
    const { user } = session

    session.user = null
    scope.run(() => usePushNotificationsSync())

    expect(sync).not.toHaveBeenCalled()

    session.user = user

    await vi.waitFor(() => expect(sync).toHaveBeenCalledOnce())
  })

  it('reads the state of the device again when the app comes back to the front', () => {
    scope.run(() => usePushNotificationsSync())

    showApp()

    expect(refresh).toHaveBeenCalledOnce()
  })
})
