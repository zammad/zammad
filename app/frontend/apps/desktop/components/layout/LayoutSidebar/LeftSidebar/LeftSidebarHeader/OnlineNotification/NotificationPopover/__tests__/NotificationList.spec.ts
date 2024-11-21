// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { generateObjectData } from '#tests/graphql/builders/index.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'

import type { OnlineNotificationConnection } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { edgesToArray } from '#shared/utils/helpers.ts'

import NotificationList from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification/NotificationPopover/NotificationList.vue'

const defaults = {
  edges: [
    {
      node: {
        id: convertToGraphQLId('OnlineNotification', 1),
        seen: true,
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
      },
      cursor: 'MQ',
    },
    {
      node: {
        id: convertToGraphQLId('OnlineNotification', 3),
        seen: false,
        createdAt: '2024-11-15T08:06:49Z',
        createdBy: {
          id: convertToGraphQLId('User', 3),
          fullname: 'Zammad Agent',
          lastname: 'Zammad',
          firstname: 'Agent',
          email: 'zammad@agent.com',
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
          id: convertToGraphQLId('Ticket', 3),
          internalId: 3,
          title: 'GitLab',
        },
      },
      cursor: 'Mg',
    },
    {
      node: {
        id: convertToGraphQLId('OnlineNotification', 2),
        seen: false,
        createdAt: '2024-10-30T06:17:35Z',
        createdBy: {
          id: convertToGraphQLId('User', 2),
          fullname: 'Agent Bar',
          lastname: 'Bar',
          firstname: 'Agent',
          email: 'bar@agent.com',
          vip: false,
          outOfOffice: false,
          outOfOfficeStartAt: null,
          outOfOfficeEndAt: null,
          active: true,
          image: null,
        },
        typeName: 'create',
        objectName: 'Ticket',
        metaObject: {
          // __typename: 'Ticket', // If not set mocker does not return this object
          id: convertToGraphQLId('Ticket', 2),
          internalId: 2,
          title: 'Mixed issues',
        },
      },
      cursor: 'Mw',
    },
  ],
  pageInfo: {
    endCursor: 'Nw',
    hasNextPage: false,
  },
}

vi.hoisted(() => {
  vi.useFakeTimers()
  vi.setSystemTime(new Date('2024-11-19T16:28:07Z'))
})

describe('NotificationList', () => {
  afterAll(() => {
    vi.useRealTimers()
  })

  it('displays a list of notifications', () => {
    const wrapper = renderComponent(NotificationList, {
      props: {
        list: edgesToArray(
          generateObjectData<OnlineNotificationConnection>(
            'OnlineNotificationConnection',
            defaults,
          ),
        ),
      },
      router: true,
    })

    const notificationsItems = wrapper.getAllByRole('listitem')

    expect(notificationsItems).toHaveLength(3)

    // Avatars
    expect(
      wrapper.getByRole('img', { name: 'Avatar (Zammad Agent)' }),
    ).toBeInTheDocument()
    expect(
      wrapper.getByRole('img', { name: 'Avatar (Admin Foo)' }),
    ).toBeInTheDocument()
    expect(
      wrapper.getByRole('img', { name: 'Avatar (Agent Bar)' }),
    ).toBeInTheDocument()

    // links to tickets
    const ticketLinks = wrapper.getAllByRole('link')

    expect(ticketLinks[0]).toHaveAttribute('href', '/tickets/1')

    expect(ticketLinks[1]).toHaveAttribute('href', '/tickets/3')

    expect(ticketLinks[2]).toHaveAttribute('href', '/tickets/2')

    // Messages
    expect(notificationsItems[0]).toHaveTextContent('Admin Foo updated ticket')
    expect(notificationsItems[0]).toHaveTextContent('Bunch of articles')

    expect(notificationsItems[1]).toHaveTextContent(
      'Zammad Agent updated ticket',
    )
    expect(notificationsItems[1]).toHaveTextContent('GitLab')

    expect(notificationsItems[2]).toHaveTextContent('Agent Bar created ticket')
    expect(notificationsItems[2]).toHaveTextContent('Mixed issues')

    // Dates
    expect(wrapper.getByLabelText('2024-11-18 16:28')).toHaveTextContent(
      '1 day ago',
    )
    expect(wrapper.getByLabelText('2024-11-15 08:06')).toHaveTextContent(
      '4 days ago',
    )
    expect(wrapper.getByLabelText('2024-10-30 06:17')).toHaveTextContent(
      '2 weeks ago',
    )
  })

  it('displays an empty message.', async () => {
    const wrapper = renderComponent(NotificationList, {
      props: {
        list: [],
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      'No unread notifications.',
    )
  })

  it('emits remove notification event', async () => {
    const list = [
      edgesToArray(
        generateObjectData<OnlineNotificationConnection>(
          'OnlineNotificationConnection',
          defaults,
        ),
      )[0],
    ]

    const wrapper = renderComponent(NotificationList, {
      props: {
        list,
      },
      router: true,
    })

    await wrapper.events.click(
      wrapper.getByRole('button', {
        name: 'Admin Foo updated ticket Bunch of articles',
      }),
    )

    expect(
      wrapper.getByRole('button', {
        name: 'Admin Foo updated ticket Bunch of articles',
      }),
    ).toHaveAttribute('aria-description', 'Remove Notification')

    expect(wrapper.emitted('remove')).toEqual([[list[0]]])
  })

  it('displays inaccessible notification message', async () => {
    const wrapper = renderComponent(NotificationList, {
      props: {
        list: edgesToArray(
          generateObjectData<OnlineNotificationConnection>(
            'OnlineNotificationConnection',
            {
              edges: [
                {
                  node: {
                    id: convertToGraphQLId('OnlineNotification', 1),
                    seen: false,
                    createdAt: '2024-11-20T11:15:37Z',
                    createdBy: null,
                    typeName: 'update',
                    objectName: 'Ticket',
                    metaObject: null,
                  },
                },
              ],
            },
          ),
        ),
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      'You can no longer see the ticket. in 18 hours',
    )

    expect(wrapper.getAllByIconName('x-lg')).toHaveLength(2)
    expect(wrapper.getByRole('presentation')).toBeInTheDocument() // x icon
  })
})
