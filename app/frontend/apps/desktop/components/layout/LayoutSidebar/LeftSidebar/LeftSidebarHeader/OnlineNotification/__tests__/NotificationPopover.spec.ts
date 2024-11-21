// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { waitForOnlineNotificationDeleteMutationCalls } from '#shared/entities/online-notification/graphql/mutations/delete.mocks.ts'
import { waitForOnlineNotificationMarkAllAsSeenMutationCalls } from '#shared/entities/online-notification/graphql/mutations/markAllAsSeen.mocks.ts'
import { mockOnlineNotificationsQuery } from '#shared/entities/online-notification/graphql/queries/onlineNotifications.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import NotificationPopover from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationPopover.vue'

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

describe('NotificationPopover', () => {
  beforeAll(() => {
    vi.useFakeTimers({ shouldAdvanceTime: true })
    vi.setSystemTime(new Date('2024-11-19T16:28:07Z'))
  })

  afterAll(() => {
    vi.useRealTimers()
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

    const wrapper = renderComponent(NotificationPopover, { router: true })

    await wrapper.events.click(
      await wrapper.findByRole('button', { name: 'mark all as read' }),
    )

    const calls = await waitForOnlineNotificationMarkAllAsSeenMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      onlineNotificationIds: [node.id],
    })
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

    const wrapper = renderComponent(NotificationPopover, { router: true })

    const list = await wrapper.findByRole('list')

    await wrapper.events.click(await within(list).findByRole('button'))

    const calls = await waitForOnlineNotificationDeleteMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      onlineNotificationId: node.id,
    })
  })
})
