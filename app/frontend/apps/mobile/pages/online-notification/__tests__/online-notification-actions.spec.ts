// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '@tests/support/components/visitView'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '@tests/support/mock-graphql-api'
import type { ExtendedIMockSubscription } from '@tests/support/mock-graphql-api'
import { OnlineNotificationsDocument } from '@shared/entities/online-notification/graphql/queries/onlineNotifications.api'
import { OnlineNotificationsCountDocument } from '@shared/entities/online-notification/graphql/subscriptions/onlineNotificationsCount.api'
import { OnlineNotificationMarkAllAsSeenDocument } from '@shared/entities/online-notification/graphql/mutations/markAllAsSeen.api'
import { OnlineNotificationDeleteDocument } from '@shared/entities/online-notification/graphql/mutations/delete.api'
import { mockOnlineNotificationQuery } from '@shared/entities/online-notification/__tests__/mocks/online-notification-mocks'
import { waitUntil } from '@tests/support/utils'
import { mockAccount } from '@tests/support/mock-account'

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
    mockAccount({
      firstname: 'John',
      lastname: 'Doe',
    })

    onlineNotificationCountSubscription = mockGraphQLSubscription(
      OnlineNotificationsCountDocument,
    )
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

  it('can delete online notification', async () => {
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

    let notificationItems = view.getAllByText('Ticket Title', {
      exact: false,
    })

    expect(notificationItems).toHaveLength(2)

    mockGraphQLApi(OnlineNotificationDeleteDocument).willResolve({
      onlineNotificationDelete: {
        errors: null,
        success: true,
      },
    })

    await view.events.click(view.getAllByIconName('mobile-delete')[0])

    notificationItems = view.getAllByText('Ticket Title', {
      exact: false,
    })

    expect(notificationItems).toHaveLength(1)
  })
})
