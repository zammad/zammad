// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '#tests/support/mock-graphql-api.ts'
import type { ExtendedIMockSubscription } from '#tests/support/mock-graphql-api.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitUntil } from '#tests/support/utils.ts'

import { mockOnlineNotificationQuery } from '#shared/entities/online-notification/__tests__/mocks/online-notification-mocks.ts'
import { OnlineNotificationDeleteDocument } from '#shared/entities/online-notification/graphql/mutations/delete.api.ts'
import { OnlineNotificationMarkAllAsSeenDocument } from '#shared/entities/online-notification/graphql/mutations/markAllAsSeen.api.ts'
import { OnlineNotificationsDocument } from '#shared/entities/online-notification/graphql/queries/onlineNotifications.api.ts'
import { OnlineNotificationsCountDocument } from '#shared/entities/online-notification/graphql/subscriptions/onlineNotificationsCount.api.ts'

let onlineNotificationCountSubscription: ExtendedIMockSubscription

const triggerNextOnlineNotificationCount = async (newCount = 0) => {
  await onlineNotificationCountSubscription.next({
    data: {
      onlineNotificationsCount: {
        __typename: 'OnlineNotificationsCountPayload',
        unseenCount: newCount,
      },
    },
  })
}

describe('selecting a online notification', () => {
  beforeEach(async () => {
    mockUserCurrent({
      firstname: 'John',
      lastname: 'Doe',
    })

    onlineNotificationCountSubscription = mockGraphQLSubscription(
      OnlineNotificationsCountDocument,
    )
  })

  it('can delete online notification', async () => {
    const readQueryStub = vi.fn()

    vi.doMock('#shared/server/apollo/client.ts', () => ({
      getApolloClient: () => ({
        cache: {
          readQuery: readQueryStub,
          writeQuery: vi.fn(),
        },
      }),
    }))

    const mockApi = mockGraphQLApi(OnlineNotificationsDocument).willResolve([
      mockOnlineNotificationQuery([
        {
          id: '111',
          seen: true,
        },
        {
          id: '222',
          seen: true,
        },
      ]),
      mockOnlineNotificationQuery([
        {
          id: '222',
          seen: true,
        },
      ]),
    ])
    const view = await visitView('/notifications')

    await waitUntil(() => mockApi.calls.resolve)

    const notificationItems = view.getAllByText('Ticket Title', {
      exact: false,
    })

    expect(notificationItems).toHaveLength(2)

    mockGraphQLApi(OnlineNotificationDeleteDocument).willResolve({
      onlineNotificationDelete: {
        errors: null,
        success: true,
      },
    })

    await view.events.click(view.getAllByIconName('delete')[0])

    expect(readQueryStub).toHaveBeenCalled()

    vi.clearAllMocks()
  })

  it('can mark all notification as read', async () => {
    const mockApi = mockGraphQLApi(OnlineNotificationsDocument).willResolve(
      mockOnlineNotificationQuery([
        {
          seen: false,
        },
        {
          seen: false,
        },
        {
          seen: true,
        },
      ]),
    )

    const view = await visitView('/notifications')

    await triggerNextOnlineNotificationCount(2)

    await waitUntil(() => mockApi.calls.resolve)

    expect(view.getAllByLabelText('Notification read')).toHaveLength(1)

    mockGraphQLApi(OnlineNotificationMarkAllAsSeenDocument).willResolve({
      onlineNotificationMarkAllAsSeen: {
        errors: null,
        onlineNotifications: [
          {
            id: '1',
            seen: true,
            __typename: 'OnlineNotification',
          },
          {
            id: '2',
            seen: true,
            __typename: 'OnlineNotification',
          },
        ],
      },
    })

    await view.events.click(view.getByText('Mark all as read'))

    expect(view.getAllByLabelText('Notification read')).toHaveLength(3)

    await triggerNextOnlineNotificationCount(0)

    expect(view.container).not.toHaveTextContent('Mark all as read')
  })

  it('can not mark notification without relation behind (no longer permission) as read', async () => {
    const mockApi = mockGraphQLApi(OnlineNotificationsDocument).willResolve(
      mockOnlineNotificationQuery([
        {
          seen: false,
        },
        {
          seen: false,
          metaObject: null,
          createdBy: null,
        },
        {
          seen: false,
        },
      ]),
    )

    const view = await visitView('/notifications')

    await triggerNextOnlineNotificationCount(2)

    await waitUntil(() => mockApi.calls.resolve)

    mockGraphQLApi(OnlineNotificationMarkAllAsSeenDocument).willResolve({
      onlineNotificationMarkAllAsSeen: {
        errors: null,
        onlineNotifications: [
          {
            id: '2',
            seen: true,
            __typename: 'OnlineNotification',
          },
        ],
      },
    })

    const noRelationNotificationItem = view.getByText(
      'You can no longer see the ticket.',
    )

    await view.events.click(noRelationNotificationItem)

    expect(view.getAllByLabelText('Unread notification')).toHaveLength(3)
  })
})
