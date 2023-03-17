// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import type { Scalars } from '@shared/graphql/types'
import NotificationItem from '../NotificationItem.vue'
import type { Props } from '../NotificationItem.vue'

const renderNotificationItem = (props: Partial<Props> = {}) => {
  return renderComponent(NotificationItem, {
    props: {
      itemId: '111',
      objectName: 'Ticket',
      typeName: 'update',
      seen: false,
      createdBy: {
        fullname: 'John Doe',
        firstname: 'John',
        lastname: 'Doe',
        active: true,
      },
      createdAt: new Date('2019-12-30 00:00:00').toISOString(),
      metaObject: {
        title: 'Ticket Title',
        id: '1',
        internalId: 1,
      },
      ...props,
    },
    router: true,
  })
}

describe('NotificationItem.vue', () => {
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

    const deleteIcon = view.getByIconName('mobile-delete')
    expect(deleteIcon).toBeInTheDocument()

    await view.events.click(deleteIcon)

    expect(view.emitted().remove).toBeTruthy()

    const emittedRemove = view.emitted().remove as Array<Array<Scalars['ID']>>
    expect(emittedRemove[0][0]).toBe('111')
  })
})
