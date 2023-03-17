// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { LastArrayElement } from 'type-fest'
import type { OnlineNotificationsQuery, Scalars } from '@shared/graphql/types'
import { nullableMock } from '@tests/support/utils'

type OnlineNotificationNode = LastArrayElement<
  OnlineNotificationsQuery['onlineNotifications']['edges']
>['node']

export const mockOnlineNotification = (
  id: Scalars['ID'],
  mockNotification: Partial<OnlineNotificationNode>,
): OnlineNotificationNode => {
  return {
    __typename: 'OnlineNotification',
    seen: false,
    createdAt: new Date().toISOString(),
    createdBy: {
      id: '123',
      fullname: 'Full Name',
      lastname: 'Name',
      firstname: 'Full',
      email: 'email@example.org',
      vip: false,
      outOfOffice: false,
      active: true,
      image: null,
    },
    typeName: 'update',
    objectName: 'Ticket',
    objectId: 111,
    metaObject: {
      __typename: 'Ticket',
      id: '111',
      internalId: 111,
      title: 'Ticket Title',
    },
    id,
    ...mockNotification,
  }
}

export const mockOnlineNotificationQuery = (
  mockNotifications: Array<Partial<OnlineNotificationNode>>,
): OnlineNotificationsQuery => {
  const edges = mockNotifications.map((item, index) => {
    const id = index + 1

    return {
      cursor: `node${id}`,
      node: mockOnlineNotification(id.toString(), item),
    }
  })

  return nullableMock<OnlineNotificationsQuery>({
    onlineNotifications: {
      edges,
      pageInfo: {
        endCursor: edges.at(-1)?.cursor || null,
        hasNextPage: false,
      },
    },
  })
}
