// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'
import { resetGlobalStates } from '#tests/support/mock-globalState.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import {
  holdLockFromAnotherTab,
  mockWebLocks,
  unmockWebLocks,
} from '#tests/support/mock-webLocks.ts'
import { waitForNextTick, waitUntil, waitUntilSpyCalled } from '#tests/support/utils.ts'

import { waitForOnlineNotificationDeleteMutationCalls } from '#shared/entities/online-notification/graphql/mutations/delete.mocks.ts'
import { OnlineNotificationDeleteAllDocument } from '#shared/entities/online-notification/graphql/mutations/deleteAll.api.ts'
import {
  mockOnlineNotificationDeleteAllMutationError,
  waitForOnlineNotificationDeleteAllMutationCalls,
} from '#shared/entities/online-notification/graphql/mutations/deleteAll.mocks.ts'
import { waitForOnlineNotificationMarkAllAsSeenMutationCalls } from '#shared/entities/online-notification/graphql/mutations/markAllAsSeen.mocks.ts'
import { mockOnlineNotificationsQuery } from '#shared/entities/online-notification/graphql/queries/onlineNotifications.mocks.ts'
import { getOnlineNotificationsCountSubscriptionHandler } from '#shared/entities/online-notification/graphql/subscriptions/onlineNotificationsCount.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import OnlineNotification from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification.vue'
import { BROWSER_NOTIFICATION_LOCK } from '#desktop/composables/useBrowserNotification.ts'

const playSoundSpy = vi.hoisted(() => vi.fn())

const node = {
  id: convertToGraphQLId('OnlineNotification', 1),
  seen: false,
  createdAt: '2024-11-18T16:28:07Z',
  createdBy: {
    id: convertToGraphQLId('User', 1),
    fullname: 'Admin Foo',
    lastname: 'Foo',
    firstname: 'Admin',
    email: 'foo@admin.com',
    vip: false,
    outOfOffice: false,
    outOfOfficeStartAt: null,
    outOfOfficeEndAt: null,
    active: true,
    image: null,
  },
  typeName: 'update',
  objectName: 'Ticket',
  metaObject: {
    id: convertToGraphQLId('Ticket', 1),
    internalId: 1,
    title: 'Bunch of articles',
  },
}
vi.mock('#shared/composables/useOnlineNotification/useOnlineNotificationSound.ts', () => ({
  useOnlineNotificationSound: () => ({
    play: playSoundSpy,
    isEnabled: { value: true },
  }),
}))

const closeWebNotificationSpy = vi.fn()
const showWebNotificationSpy = vi.fn()
const requestPermissionSpy = vi.fn(() => Promise.resolve('granted'))

// The shared browser notification instance snapshots the permission when it is
//   created, so every example gets a fresh one.
vi.mock('@vueuse/core', async (importOriginal) => ({
  ...(await importOriginal<typeof import('@vueuse/core')>()),
  createGlobalState: (await import('#tests/support/mock-globalState.ts')).createGlobalState,
}))

// The constructor is the spy for shown notifications. VueUse probes the support
//   with an untitled notification, which is not one.
const mockNotification = (permission: NotificationPermission) => {
  resetGlobalStates()

  Object.defineProperty(globalThis, 'Notification', {
    value: class {
      static permission = permission

      static requestPermission = requestPermissionSpy

      close = closeWebNotificationSpy

      constructor(title: string, options?: NotificationOptions) {
        if (title) showWebNotificationSpy(title, options)
      }
    },
    writable: true,
    configurable: true,
  })
}

const waitForConfirmationMock = vi.fn().mockImplementation(() => true)

vi.mock('#shared/composables/useConfirmation.ts', () => ({
  useConfirmation: () => ({
    waitForConfirmation: waitForConfirmationMock,
  }),
}))

describe('OnlineNotification', () => {
  afterEach(() => {
    unmockWebLocks()
  })

  beforeEach(() => {
    mockNotification('granted')

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
      slots: {
        default: '<CommonIcon name="logo" />',
      },
      router: true,
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 0,
      },
    })

    expect(wrapper.getByRole('button', { name: 'Show notifications' })).toBeInTheDocument()

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

    expect(wrapper.getByRole('status', { name: 'Unseen notifications count' })).toHaveTextContent(
      '10',
    )
  })

  it('makes a notification sound if a new unseen message comes in', async () => {
    mockOnlineNotificationsQuery({
      onlineNotifications: {
        edges: [{ node }],
        pageInfo: {
          endCursor: 'Nw',
          hasNextPage: false,
        },
      },
    })

    renderComponent(OnlineNotification, {
      router: true,
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 0,
      },
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 1,
      },
    })

    await waitUntilSpyCalled(playSoundSpy)

    expect(playSoundSpy).toHaveBeenCalled()
  })

  it('does not play a notification sound if the sound is disabled', async () => {
    mockNotification('default')

    mockUserCurrent({
      preferences: {
        notification_sound: {
          enabled: false,
          notification_sound: 'Xylo.mp3',
        },
      },
    })

    renderComponent(OnlineNotification, {
      router: true,
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 1,
      },
    })

    expect(playSoundSpy).not.toHaveBeenCalled()
  })

  it.each([true, false])(
    'does not ask for the notification permission on mount when the sound is %s',
    async (enabled) => {
      mockNotification('default')

      mockUserCurrent({
        preferences: {
          notification_sound: {
            enabled,
            notification_sound: 'Xylo.mp3',
          },
        },
      })

      renderComponent(OnlineNotification, {
        router: true,
      })

      await waitForNextTick()

      expect(requestPermissionSpy).not.toHaveBeenCalled()
    },
  )

  it('shows a browser notification when the permission is granted', async () => {
    mockOnlineNotificationsQuery({
      onlineNotifications: {
        edges: [{ node }],
        pageInfo: {
          endCursor: 'Nw',
          hasNextPage: false,
        },
      },
    })

    renderComponent(OnlineNotification, {
      router: true,
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 0,
      },
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 1,
      },
    })

    await waitUntilSpyCalled(showWebNotificationSpy)

    expect(showWebNotificationSpy).toHaveBeenCalledWith(
      expect.any(String),
      expect.objectContaining({ tag: node.id, silent: true }),
    )
    expect(requestPermissionSpy).not.toHaveBeenCalled()
  })

  it.each(['default', 'denied'] as const)(
    'skips the browser notification silently when the permission is %s',
    async (permission) => {
      mockNotification(permission)

      mockOnlineNotificationsQuery({
        onlineNotifications: {
          edges: [{ node }],
          pageInfo: {
            endCursor: 'Nw',
            hasNextPage: false,
          },
        },
      })

      const wrapper = renderComponent(OnlineNotification, {
        router: true,
      })

      await getOnlineNotificationsCountSubscriptionHandler().trigger({
        onlineNotificationsCount: {
          unseenCount: 0,
        },
      })

      await getOnlineNotificationsCountSubscriptionHandler().trigger({
        onlineNotificationsCount: {
          unseenCount: 1,
        },
      })

      await waitUntilSpyCalled(playSoundSpy)

      expect(showWebNotificationSpy).not.toHaveBeenCalled()
      expect(requestPermissionSpy).not.toHaveBeenCalled()
      expect(wrapper.getByRole('status', { name: 'Unseen notifications count' })).toHaveTextContent(
        '1',
      )
    },
  )

  it('leaves the browser notification to the tab the agent used last', async () => {
    mockWebLocks()
    holdLockFromAnotherTab(BROWSER_NOTIFICATION_LOCK)

    mockOnlineNotificationsQuery({
      onlineNotifications: {
        edges: [{ node }],
        pageInfo: {
          endCursor: 'Nw',
          hasNextPage: false,
        },
      },
    })

    const wrapper = renderComponent(OnlineNotification, {
      router: true,
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 0,
      },
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 1,
      },
    })

    await waitUntilSpyCalled(playSoundSpy)

    expect(showWebNotificationSpy).not.toHaveBeenCalled()
    expect(wrapper.getByRole('status', { name: 'Unseen notifications count' })).toHaveTextContent(
      '1',
    )
  })

  it('closes its browser notifications when another tab takes over', async () => {
    mockWebLocks()

    mockOnlineNotificationsQuery({
      onlineNotifications: {
        edges: [{ node }],
        pageInfo: {
          endCursor: 'Nw',
          hasNextPage: false,
        },
      },
    })

    renderComponent(OnlineNotification, {
      router: true,
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 0,
      },
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 1,
      },
    })

    await waitUntilSpyCalled(showWebNotificationSpy)

    holdLockFromAnotherTab(BROWSER_NOTIFICATION_LOCK, true)

    await waitUntilSpyCalled(closeWebNotificationSpy)

    expect(closeWebNotificationSpy).toHaveBeenCalledOnce()
  })

  it('does not play a sound if the user has not granted permission', async () => {
    mockNotification('denied')

    renderComponent(OnlineNotification, {
      router: true,
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 1,
      },
    })

    expect(playSoundSpy).not.toHaveBeenCalled()
  })

  it('does not play a sound if the user has a pending permission prompt', async () => {
    mockNotification('default')

    renderComponent(OnlineNotification, {
      router: true,
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 1,
      },
    })

    expect(playSoundSpy).not.toHaveBeenCalled()
  })

  it('marks all notifications as read.', async () => {
    mockOnlineNotificationsQuery({
      onlineNotifications: {
        edges: [
          {
            node,
          },
        ],
        pageInfo: {
          endCursor: 'Nw',
          hasNextPage: false,
        },
      },
    })

    const wrapper = renderComponent(OnlineNotification, {
      router: true,
    })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Show notifications' }))

    await wrapper.events.click(await wrapper.findByRole('button', { name: 'mark all as read' }))

    const calls = await waitForOnlineNotificationMarkAllAsSeenMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      onlineNotificationIds: [node.id],
    })
  })

  it('clears all notifications once everything is read', async () => {
    mockOnlineNotificationsQuery({
      onlineNotifications: {
        edges: [
          {
            node: { ...node, seen: true },
          },
        ],
        pageInfo: {
          endCursor: 'Nw',
          hasNextPage: false,
        },
      },
    })

    const wrapper = renderComponent(OnlineNotification, {
      router: true,
    })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Show notifications' }))

    await wrapper.events.click(await wrapper.findByRole('button', { name: 'clear all' }))

    expect(waitForConfirmationMock).toHaveBeenCalled()

    const calls = await waitForOnlineNotificationDeleteAllMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({})
  })

  it("doesn't clear notifications when confirmation is cancelled", async () => {
    waitForConfirmationMock.mockImplementationOnce(() => false)

    mockOnlineNotificationsQuery({
      onlineNotifications: {
        edges: [
          {
            node: { ...node, seen: true },
          },
        ],
        pageInfo: {
          endCursor: 'Nw',
          hasNextPage: false,
        },
      },
    })

    const wrapper = renderComponent(OnlineNotification, {
      router: true,
    })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Show notifications' }))

    await wrapper.events.click(await wrapper.findByRole('button', { name: 'clear all' }))

    expect(waitForConfirmationMock).toHaveBeenCalled()

    await waitForNextTick()

    expect(getGraphQLMockCalls(OnlineNotificationDeleteAllDocument)).toHaveLength(0)
  })

  it('keeps the focus away from the notification button while the confirmation is open', async () => {
    mockOnlineNotificationsQuery({
      onlineNotifications: {
        edges: [
          {
            node: { ...node, seen: true },
          },
        ],
        pageInfo: {
          endCursor: 'Nw',
          hasNextPage: false,
        },
      },
    })

    const wrapper = renderComponent(OnlineNotification, {
      router: true,
    })

    const notificationButton = wrapper.getByRole('button', { name: 'Show notifications' })

    notificationButton.focus()
    await wrapper.events.keyboard('{Enter}')

    const clearAllButton = await wrapper.findByRole('button', { name: 'clear all' })

    // The popover moves the focus into its own tab trap after opening.
    await waitUntil(() => document.activeElement !== notificationButton)

    clearAllButton.focus()
    await wrapper.events.keyboard('{Enter}')

    expect(waitForConfirmationMock).toHaveBeenCalled()

    await waitForNextTick()
    await waitForNextTick()

    expect(notificationButton).not.toHaveFocus()
  })

  it('reopens the notification popover when the confirmation is cancelled', async () => {
    waitForConfirmationMock.mockImplementationOnce(() => false)

    mockOnlineNotificationsQuery({
      onlineNotifications: {
        edges: [
          {
            node: { ...node, seen: true },
          },
        ],
        pageInfo: {
          endCursor: 'Nw',
          hasNextPage: false,
        },
      },
    })

    const wrapper = renderComponent(OnlineNotification, {
      router: true,
    })

    const notificationButton = wrapper.getByRole('button', { name: 'Show notifications' })

    notificationButton.focus()
    await wrapper.events.keyboard('{Enter}')

    const clearAllButton = await wrapper.findByRole('button', { name: 'clear all' })

    // The popover moves the focus into its own tab trap after opening.
    await waitUntil(() => document.activeElement !== notificationButton)

    clearAllButton.focus()
    await wrapper.events.keyboard('{Enter}')

    expect(waitForConfirmationMock).toHaveBeenCalled()

    expect(await wrapper.findByRole('button', { name: 'clear all' })).toBeInTheDocument()
    expect(notificationButton).not.toHaveFocus()
  })

  it('keeps working when clearing all notifications fails', async () => {
    mockOnlineNotificationDeleteAllMutationError('Something went wrong', {
      type: GraphQLErrorTypes.UnknownError,
    })

    mockOnlineNotificationsQuery({
      onlineNotifications: {
        edges: [{ node }],
        pageInfo: {
          endCursor: 'Nw',
          hasNextPage: false,
        },
      },
    })

    const wrapper = renderComponent(OnlineNotification, {
      router: true,
    })

    // A rising unseen count shows a web notification, which is the one that must survive
    //   the failed mutation.
    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 0,
      },
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 1,
      },
    })

    await waitUntilSpyCalled(showWebNotificationSpy)

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Show notifications' }))

    await wrapper.events.click(await wrapper.findByRole('button', { name: 'clear all' }))

    expect(waitForConfirmationMock).toHaveBeenCalled()

    await waitForOnlineNotificationDeleteAllMutationCalls()

    await waitForNextTick()
    await waitForNextTick()

    expect(closeWebNotificationSpy).not.toHaveBeenCalled()
  })

  it('closes open web notifications after clearing all notifications', async () => {
    mockOnlineNotificationsQuery({
      onlineNotifications: {
        edges: [{ node }],
        pageInfo: {
          endCursor: 'Nw',
          hasNextPage: false,
        },
      },
    })

    const wrapper = renderComponent(OnlineNotification, {
      router: true,
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 0,
      },
    })

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 1,
      },
    })

    await waitUntilSpyCalled(showWebNotificationSpy)

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Show notifications' }))

    await wrapper.events.click(await wrapper.findByRole('button', { name: 'clear all' }))

    await waitForOnlineNotificationDeleteAllMutationCalls()

    await waitUntilSpyCalled(closeWebNotificationSpy)

    expect(closeWebNotificationSpy).toHaveBeenCalled()
  })

  it('removes a notification', async () => {
    mockOnlineNotificationsQuery({
      onlineNotifications: {
        edges: [
          {
            node,
          },
        ],
        pageInfo: {
          endCursor: 'Nw',
          hasNextPage: false,
        },
      },
    })

    const wrapper = renderComponent(OnlineNotification, {
      router: true,
    })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Show notifications' }))

    const list = await wrapper.findByRole('list')

    await wrapper.events.click(await within(list).findByRole('button'))

    const calls = await waitForOnlineNotificationDeleteMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      onlineNotificationId: node.id,
    })
  })
})
