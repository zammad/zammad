// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

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

const testNotifications: any[] = [
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
]

describe('testing online notification a11y', () => {
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

  it('has no accessibility violations', async () => {
    const mockApi = mockGraphQLApi(OnlineNotificationsDocument).willResolve(
      mockOnlineNotificationQuery(testNotifications),
    )

    const view = await visitView('/notifications')

    await waitUntil(() => mockApi.calls.resolve)

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
