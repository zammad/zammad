// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { getOnlineNotificationsCountSubscriptionHandler } from '#shared/entities/online-notification/graphql/subscriptions/onlineNotificationsCount.mocks.ts'

import OnlineNotification from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification.vue'

import '#tests/graphql/builders/mocks.ts'

const playSoundSpy = vi.hoisted(() => vi.fn())

let notificationPermission = vi.hoisted<string | undefined>(() => 'granted')

vi.mock(
  '#shared/composables/useOnlineNotification/useOnlineNotificationSound.ts',
  () => ({
    useOnlineNotificationSound: () => ({
      play: playSoundSpy,
      isEnabled: { value: true },
    }),
  }),
)

vi.mock('@vueuse/core', async (importOriginal) => {
  const module = await importOriginal()

  return {
    ...(module as typeof import('@vueuse/core')),
    usePermission: () => ({
      value: notificationPermission,
    }),
  }
})

describe('OnlineNotification', () => {
  beforeEach(() => {
    mockUserCurrent({
      preferences: {
        notification_sound: {
          enabled: true,
          notification_sound: 'Xylo.mp3',
        },
      },
    })
  })

  it('displays notification logo without unseen notifications', async () => {
    const wrapper = renderComponent(OnlineNotification, {
      props: { collapsed: false },
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 0,
      },
    })

    expect(
      wrapper.getByRole('button', { name: 'Show notifications' }),
    ).toBeInTheDocument()

    expect(wrapper.getByIconName('logo')).toBeInTheDocument()

    expect(
      wrapper.queryByRole('status', { name: 'Unseen notifications count' }),
    ).not.toBeInTheDocument()
  })

  it('displays unseen notifications count', async () => {
    const wrapper = renderComponent(OnlineNotification)

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 10,
      },
    })

    expect(
      wrapper.getByRole('status', { name: 'Unseen notifications count' }),
    ).toHaveTextContent('10')
  })

  it('makes a notification sound if a new unseen message comes in', async () => {
    renderComponent(OnlineNotification)

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 1,
      },
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 2,
      },
    })

    expect(playSoundSpy).toHaveBeenCalled()
  })

  it('does not play a notification sound if the sound is disabled', async () => {
    mockUserCurrent({
      preferences: {
        notification_sound: {
          enabled: false,
          notification_sound: 'Xylo.mp3',
        },
      },
    })

    renderComponent(OnlineNotification)

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 1,
      },
    })

    expect(playSoundSpy).not.toHaveBeenCalled()
  })

  it('asks for notification permission if session starts for the first time', async () => {
    notificationPermission = undefined

    const spy = vi.spyOn(Notification, 'requestPermission')

    renderComponent(OnlineNotification)

    await waitForNextTick()

    expect(spy).toHaveBeenCalled()
  })

  it('does not play a sound if the user has not granted permission', async () => {
    notificationPermission = 'denied'

    renderComponent(OnlineNotification)

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 1,
      },
    })

    expect(playSoundSpy).not.toHaveBeenCalled()
  })

  it('does not play a sound if the user has a pending permission prompt', async () => {
    notificationPermission = 'prompt'

    renderComponent(OnlineNotification)

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 1,
      },
    })

    expect(playSoundSpy).not.toHaveBeenCalled()
  })
})
