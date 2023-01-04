// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

const now = new Date('2022-01-03 00:00:00')
vi.setSystemTime(now)

import { renderComponent } from '@tests/support/components'
import ActivityMessage from '../ActivityMessage.vue'
import type { Props } from '../ActivityMessage.vue'

const renderActivityMessage = (props: Partial<Props> = {}) => {
  return renderComponent(ActivityMessage, {
    props: {
      objectName: 'Ticket',
      typeName: 'update',
      createdBy: {
        fullname: 'John Doe',
        firstname: 'John',
        lastname: 'Doe',
        active: true,
      },
      createdAt: new Date('2022-01-01 00:00:00').toISOString(),
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
  afterEach(() => {
    vi.useRealTimers()
  })

  it('check update activity message output', () => {
    const view = renderActivityMessage()

    expect(view.container).toHaveTextContent(
      'John Doe updated ticket Ticket Title',
    )
  })

  it('check create activity message output', () => {
    const view = renderActivityMessage({
      typeName: 'create',
    })

    expect(view.container).toHaveTextContent(
      'John Doe created ticket Ticket Title',
    )
  })

  it('check that avatar exists', () => {
    const view = renderActivityMessage()

    const avatar = view.getByTestId('common-avatar')

    expect(avatar).toHaveTextContent('JD')
  })

  it('check that link exists', () => {
    const view = renderActivityMessage()

    const link = view.getByRole('link')
    expect(link).toHaveAttribute('href', 'tickets/1')
  })

  it('check that create date exists', () => {
    vi.setSystemTime(now)

    const view = renderActivityMessage()
    expect(view.getByText(/2 days ago/)).toBeInTheDocument()
  })

  it('no output for not existing builder', (context) => {
    context.skipConsole = true

    const view = renderActivityMessage({
      objectName: 'NotExisting',
    })

    expect(view.html()).not.toContain('a')
  })
})
