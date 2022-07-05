// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

const date = new Date('2020-01-01 00:00:00')

vi.setSystemTime(date)

import { renderComponent } from '@tests/support/components'
import { getMockedNotification } from '../../__tests__/mocks'
import NotificationItem from '../NotificationItem.vue'

describe('notification item', () => {
  test('renders correctly', async () => {
    const notification = getMockedNotification({
      read: true,
      title: 'Title',
      createdAt: new Date('2019-12-30 00:00:00').toISOString(),
    })

    const view = renderComponent(NotificationItem, {
      props: {
        notification,
      },
      form: true,
    })

    expect(view.getByTestId('notificationRead')).not.toHaveClass('bg-blue')

    await view.rerender({
      notification: {
        ...notification,
        read: false,
      },
    })

    expect(view.getByTestId('notificationRead')).toHaveClass('bg-blue')

    expect(view.getByText('JB'), 'has avatar').toBeInTheDocument()
    expect(
      view.getByText(new RegExp(`#${notification.id}`)),
      'has id',
    ).toBeInTheDocument()

    expect(view.getByText(/^Title$/), 'has title').toBeInTheDocument()
    expect(view.getByText(/2 days ago/)).toBeInTheDocument()

    await view.rerender({
      notification: {
        ...notification,
        message: 'Some Message',
      },
    })

    expect(view.getByText(/Title:/)).toBeInTheDocument()
    expect(view.getByText(/“Some Message”/)).toBeInTheDocument()

    vi.useRealTimers()

    await view.events.click(view.getByIconName('trash'))

    expect(view.emitted().remove).toBeDefined()
  })

  test('can delete notification', async () => {
    const notification = getMockedNotification()

    const view = renderComponent(NotificationItem, {
      props: {
        notification,
      },
      form: true,
    })

    await view.events.click(view.getByIconName('trash'))

    expect(view.emitted().remove).toBeDefined()
  })
})
