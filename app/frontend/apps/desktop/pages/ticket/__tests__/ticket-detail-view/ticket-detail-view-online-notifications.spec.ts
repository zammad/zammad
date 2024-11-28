// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { nullableMock } from '#tests/support/utils.ts'

import { waitForOnlineNotificationSeenMutationCalls } from '#shared/entities/online-notification/graphql/mutations/seen.mocks.ts'
import { mockOnlineNotificationsQuery } from '#shared/entities/online-notification/graphql/queries/onlineNotifications.mocks.ts'
import { getOnlineNotificationsCountSubscriptionHandler } from '#shared/entities/online-notification/graphql/subscriptions/onlineNotificationsCount.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

describe('Ticket detail: sidebar - online notifications', () => {
  beforeEach(() => {
    mockTicketQuery({
      ticket: createDummyTicket(),
    })
  })

  describe('when there are notifications', () => {
    beforeEach(async () => {
      mockOnlineNotificationsQuery({
        onlineNotifications: {
          edges: [
            {
              node: {
                id: convertToGraphQLId('OnlineNotification', 1),
                seen: false,
                typeName: 'create',
                objectName: 'Ticket',
                metaObject: {
                  id: convertToGraphQLId('Ticket', 1),
                  internalId: 1,
                  title: 'Test ticket',
                },
              },
            },
          ],
        },
      })
    })

    it('shows no count and notifications', async () => {
      const view = await visitView('/tickets/1')

      await getOnlineNotificationsCountSubscriptionHandler().trigger({
        onlineNotificationsCount: {
          unseenCount: 1,
        },
      })

      const notificationsButton =
        await view.findByLabelText('Show notifications')

      await view.events.click(notificationsButton)

      const list = await view.findByRole('region')

      expect(
        within(list).getByText('created ticket', { exact: false }),
      ).toBeInTheDocument()

      expect(
        view.getByRole('status', { name: 'Unseen notifications count' }),
      ).toHaveTextContent('1')
    })
  })

  it('updates seen if notification is clicked', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true })
    vi.setSystemTime(new Date('2024-11-19T16:28:07Z'))

    mockOnlineNotificationsQuery({
      onlineNotifications: {
        edges: [
          {
            node: {
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
                title: 'Test',
              },
            },
          },
        ],
        pageInfo: {
          endCursor: 'Nw',
          hasNextPage: false,
        },
      },
    })

    const view = await visitView('/tickets/1')

    await getOnlineNotificationsCountSubscriptionHandler().trigger({
      onlineNotificationsCount: {
        unseenCount: 1,
      },
    })

    const notificationsButton = await view.findByLabelText('Show notifications')

    await view.events.click(notificationsButton)

    const list = await view.findByRole('region', { name: 'Notifications' })

    await view.events.click(
      within(list).getByRole('link', {
        name: 'Avatar (Admin Foo) Admin Foo updated ticket Test 2024-11-18 16:28',
      }),
    )

    const calls = await waitForOnlineNotificationSeenMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      objectId: convertToGraphQLId('Ticket', 1),
    })

    vi.useRealTimers()
  })

  describe('when there are no notifications', () => {
    beforeEach(() => {
      mockOnlineNotificationsQuery({
        onlineNotifications: {
          edges: nullableMock([]),
        },
      })
    })

    it('shows no count and notifications', async () => {
      const view = await visitView('/tickets/1')

      await getOnlineNotificationsCountSubscriptionHandler().trigger({
        onlineNotificationsCount: {
          unseenCount: 0,
        },
      })

      const notificationsButton =
        await view.findByLabelText('Show notifications')

      await view.events.click(notificationsButton)

      const list = await view.findByRole('region', { name: 'Notifications' })

      expect(
        within(list).getByText('No unread notifications.'),
      ).toBeInTheDocument()

      expect(
        view.queryByRole('status', { name: 'Unseen notifications count' }),
      ).not.toBeInTheDocument()
    })
  })
})
