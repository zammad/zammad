// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import {
  mockGraphQLApi,
  mockGraphQLSubscription,
} from '#tests/support/mock-graphql-api.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitUntil } from '#tests/support/utils.ts'

import { mockOnlineNotificationQuery } from '#shared/entities/online-notification/__tests__/mocks/online-notification-mocks.ts'
import { OnlineNotificationsDocument } from '#shared/entities/online-notification/graphql/queries/onlineNotifications.api.ts'
import { OnlineNotificationsCountDocument } from '#shared/entities/online-notification/graphql/subscriptions/onlineNotificationsCount.api.ts'

describe('selecting a online notification', () => {
  beforeEach(async () => {
    mockUserCurrent({
      firstname: 'John',
      lastname: 'Doe',
    })

    const userUpdateSubscription = mockGraphQLSubscription(
      OnlineNotificationsCountDocument,
    )

    await userUpdateSubscription.next({
      data: {
        onlineNotificationsCount: {
          __typename: 'OnlineNotificationsCountPayload',
          unseenCount: 2,
        },
      },
    })
  })

  it('shows a list of online notifications', async () => {
    const mockApi = mockGraphQLApi(OnlineNotificationsDocument).willResolve(
      mockOnlineNotificationQuery([
        {
          metaObject: {
            __typename: 'Ticket',
            id: '111',
            internalId: 111,
            title: 'Ticket Title 1',
          },
        },
        {
          metaObject: {
            __typename: 'Ticket',
            id: '222',
            internalId: 222,
            title: 'Ticket Title 2',
          },
        },
        {
          seen: true,
          metaObject: {
            __typename: 'Ticket',
            id: '333',
            internalId: 333,
            title: 'Ticket Title 3',
          },
        },
      ]),
    )

    const view = await visitView('/notifications')

    await waitUntil(() => mockApi.calls.resolve)

    const notificationItems = view.getAllByText('Ticket Title', {
      exact: false,
    })

    expect(notificationItems).toHaveLength(3)
    expect(view.getAllByLabelText('Notification read')).toHaveLength(1)
    expect(view.getAllByLabelText('Unread notification')).toHaveLength(2)
  })

  it('can enter the linked object page', async () => {
    const mockApi = mockGraphQLApi(OnlineNotificationsDocument).willResolve(
      mockOnlineNotificationQuery([
        {
          metaObject: {
            __typename: 'Ticket',
            id: '111',
            internalId: 111,
            title: 'Ticket Title 1',
          },
        },
        {
          metaObject: {
            __typename: 'Ticket',
            id: '222',
            internalId: 222,
            title: 'Ticket Title 2',
          },
        },
      ]),
    )

    const view = await visitView('/notifications')

    await waitUntil(() => mockApi.calls.resolve)

    const notificationItem = view.getByText('Ticket Title 1', {
      exact: false,
    })

    expect(view.getLinkFromElement(notificationItem)).toHaveAttribute(
      'href',
      '/mobile/tickets/111',
    )
  })

  it('shows a list of online notifications which includes also items without permission to the relation', async () => {
    const mockApi = mockGraphQLApi(OnlineNotificationsDocument).willResolve(
      mockOnlineNotificationQuery([
        {
          metaObject: {
            __typename: 'Ticket',
            id: '111',
            internalId: 111,
            title: 'Ticket Title 1',
          },
        },
        {
          metaObject: null,
          createdBy: null,
        },
        {
          seen: true,
          metaObject: {
            __typename: 'Ticket',
            id: '333',
            internalId: 333,
            title: 'Ticket Title 3',
          },
        },
      ]),
    )

    const view = await visitView('/notifications')

    await waitUntil(() => mockApi.calls.resolve)

    const notificationItems = view.getAllByText('Ticket Title', {
      exact: false,
    })

    expect(notificationItems).toHaveLength(2)

    const noRelationNotificationItems = view.getAllByText(
      'You can no longer see the ticket.',
    )
    expect(noRelationNotificationItems).toHaveLength(1)
  })
})
