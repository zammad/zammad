// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { reactive, ref } from 'vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { usePushNotificationsStore } from '#mobile/entities/user/current/stores/pushNotifications.ts'
import type {
  PushNotificationState,
  PushNotificationUnavailableReason,
} from '#mobile/entities/user/current/stores/types.ts'

vi.mock('#mobile/entities/user/current/stores/pushNotifications.ts')

const mockPushNotifications = (
  state: PushNotificationState,
  unavailableReason: PushNotificationUnavailableReason | null = null,
  isLoading = false,
) => {
  const enable = vi.fn()
  const disable = vi.fn()
  const currentState = ref(state)

  vi.mocked(usePushNotificationsStore).mockReturnValue(
    reactive({
      state: currentState,
      unavailableReason,
      isLoading,
      enable,
      disable,
      refresh: vi.fn(async () => null),
    }) as unknown as ReturnType<typeof usePushNotificationsStore>,
  )

  return { enable, disable, currentState }
}

describe('push notifications on the account page', () => {
  beforeEach(() => {
    mockUserCurrent({ firstname: 'John', lastname: 'Doe' })
  })

  it('hides the toggle for users who receive no online notifications', async () => {
    mockPushNotifications('hidden')

    const view = await visitView('/account')

    expect(view.queryByLabelText('Push notifications on this device')).not.toBeInTheDocument()
  })

  it.each([
    [
      'insecure-connection',
      'Push notifications need a secure connection. Open this app via HTTPS.',
    ],
    [
      'not-installed',
      'Push notifications are only available after adding this app to the home screen.',
    ],
    ['unsupported-browser', 'This browser does not support push notifications.'],
    [
      'not-configured',
      'Push notifications are not set up on this system. Please contact your administrator.',
    ],
    [
      'service-worker-installing',
      'Push notifications become available once the app has finished loading. This can take a moment.',
    ],
    [
      'service-worker-missing',
      'Push notifications are not available because the app is not fully loaded. Please reload the app.',
    ],
    ['push-service-rejected', 'This browser cannot register for push notifications.'],
  ] as const)('locks the toggle and explains what is missing: %s', async (reason, help) => {
    const { enable } = mockPushNotifications('unavailable', reason)

    const view = await visitView('/account')

    const toggle = view.getByLabelText('Push notifications on this device')

    expect(toggle).toBeDisabled()
    expect(toggle).not.toBeChecked()
    expect(view.getByText(help)).toBeInTheDocument()

    await view.events.click(toggle)

    expect(enable).not.toHaveBeenCalled()
  })

  it('enables push notifications for this device', async () => {
    const { enable } = mockPushNotifications('disabled')

    const view = await visitView('/account')

    expect(
      view.getByText('Turn on to get notified on this device about updates to your tickets.'),
    ).toBeInTheDocument()

    await view.events.click(view.getByLabelText('Push notifications on this device'))

    expect(enable).toHaveBeenCalled()
  })

  it('follows a change made in the settings of the device without switching anything', async () => {
    const { enable, disable, currentState } = mockPushNotifications('enabled')

    const view = await visitView('/account')

    const toggle = () => view.getByLabelText('Push notifications on this device')

    currentState.value = 'denied'

    await vi.waitFor(() => expect(toggle()).toBeDisabled())
    expect(toggle()).not.toBeChecked()

    currentState.value = 'enabled'

    await vi.waitFor(() => expect(toggle()).toBeChecked())
    expect(disable).not.toHaveBeenCalled()
    expect(enable).not.toHaveBeenCalled()
  })

  it('disables push notifications for this device', async () => {
    const { disable } = mockPushNotifications('enabled')

    const view = await visitView('/account')

    const toggle = view.getByLabelText('Push notifications on this device')

    expect(toggle).toBeChecked()
    expect(
      view.getByText('You get notified on this device about updates to your tickets.'),
    ).toBeInTheDocument()

    await view.events.click(toggle)

    expect(disable).toHaveBeenCalled()
  })

  it('explains a push that stopped working and lets it be turned on again', async () => {
    const { enable } = mockPushNotifications('expired')

    const view = await visitView('/account')

    const toggle = view.getByLabelText('Push notifications on this device')

    expect(toggle).not.toBeDisabled()
    expect(toggle).not.toBeChecked()
    expect(
      view.getByText(
        'Push notifications stopped working on this device. Turn them on again to keep receiving them.',
      ),
    ).toBeInTheDocument()

    await view.events.click(toggle)

    expect(enable).toHaveBeenCalled()
  })

  it('ignores a tap while push notifications are still being switched, without locking the toggle', async () => {
    const { enable, disable } = mockPushNotifications('disabled', null, true)

    const view = await visitView('/account')

    const toggle = view.getByLabelText('Push notifications on this device')

    expect(toggle).not.toBeDisabled()

    await view.events.click(toggle)

    expect(enable).not.toHaveBeenCalled()
    expect(disable).not.toHaveBeenCalled()
  })

  it('explains a blocked browser permission', async () => {
    mockPushNotifications('denied')

    const view = await visitView('/account')

    expect(view.getByLabelText('Push notifications on this device')).toBeDisabled()
    expect(
      view.getByText('Notifications are turned off for this app in the settings of this device.'),
    ).toBeInTheDocument()
  })
})
