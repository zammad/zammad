// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { generateObjectData } from '#tests/graphql/builders/index.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'

import { OnlineNotificationDeleteDocument } from '#shared/entities/online-notification/graphql/mutations/delete.api.ts'
import type {
  OnlineNotification,
  Scalars,
  Ticket,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import NotificationItem from '../NotificationItem.vue'

vi.mock('#shared/server/apollo/client.ts', () => ({
  getApolloClient: () => ({
    cache: {
      writeQuery: vi.fn(),
      readQuery: vi.fn(),
    },
  }),
}))

const userId = convertToGraphQLId('User', 100)

const renderNotificationItem = (
  activityProps: Partial<OnlineNotification> = {},
) => {
  mockGraphQLApi(OnlineNotificationDeleteDocument).willResolve({
    onlineNotificationDelete: {
      errors: null,
      success: true,
    },
  })

  const finishedProps = {
    activity: {
      id: convertToGraphQLId('OnlineNotification', 1),
      objectName: 'Ticket',
      typeName: 'update',
      seen: false,
      createdBy: {
        id: userId,
        fullname: 'John Doe',
        firstname: 'John',
        lastname: 'Doe',
        active: true,
      },
      createdAt: new Date('2019-12-30 00:00:00').toISOString(),
      metaObject: generateObjectData<Ticket>('Ticket', {
        title: 'Ticket Title',
        id: convertToGraphQLId('Ticket', 1),
        internalId: 1,
      }),
      ...activityProps,
    } as OnlineNotification,
  }

  return renderComponent(NotificationItem, {
    props: finishedProps,
    router: true,
  })
}

describe('NotificationItem.vue', () => {
  afterAll(() => {
    vi.clearAllMocks()
  })

  it('check activity message output', () => {
    const view = renderNotificationItem()

    expect(view.container).toHaveTextContent(
      'John Doe updated ticket Ticket Title',
    )
  })

  it('unseen identifier visible', () => {
    const view = renderNotificationItem()

    expect(view.getByLabelText('Unread notification')).toBeInTheDocument()
  })

  it('seen identifier visible', () => {
    const view = renderNotificationItem({
      seen: true,
    })

    expect(view.getByLabelText('Notification read')).toBeInTheDocument()
  })

  it('can delete online notification', async () => {
    const view = renderNotificationItem()

    const deleteIcon = view.getByIconName('delete')
    expect(deleteIcon).toBeInTheDocument()

    await view.events.click(deleteIcon)

    expect(view.emitted().remove).toBeTruthy()

    const emittedRemove = view.emitted().remove as Array<
      Array<Scalars['ID']['output']>
    >

    expect(emittedRemove[0][0]).toBe(
      convertToGraphQLId('OnlineNotification', 1),
    )
  })

  it('should emit "seen" event on click for none linked notifications', async () => {
    const view = renderNotificationItem({
      metaObject: undefined,
      createdBy: undefined,
    })

    const item = view.getByText('You can no longer see the ticket.')

    await view.events.click(item)

    expect(view.emitted().seen).toBeTruthy()

    const emittedSeen = view.emitted().seen as Array<
      Array<Scalars['ID']['output']>
    >
    expect(emittedSeen[0][0]).toBe(convertToGraphQLId('OnlineNotification', 1))
  })
})
