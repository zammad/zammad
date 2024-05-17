// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import UserItem from '../UserItem.vue'

import type { UserItemData } from '../types.ts'

vi.hoisted(() => {
  const now = new Date(2022, 1, 1, 20, 0, 0, 0)
  vi.setSystemTime(now)
})

describe('user item display', () => {
  it('renders correctly', () => {
    const user: UserItemData = {
      id: '123',
      ticketsCount: {
        open: 2,
        closed: 0,
      },
      firstname: 'John',
      lastname: 'Doe',
      updatedAt: new Date(2022, 1, 1, 10, 0, 0, 0).toISOString(),
      updatedBy: {
        id: '456',
        fullname: 'Jane Doe',
      },
      organization: {
        name: 'organization',
      },
    }

    const view = renderComponent(UserItem, {
      props: {
        entity: user,
      },
      store: true,
    })

    expect(view.getByText('JD')).toBeInTheDocument() // avatar
    expect(view.getByText(/organization/)).toBeInTheDocument()
    expect(view.getByText(/2 tickets/)).toBeInTheDocument()
    expect(view.getByText('John Doe')).toBeInTheDocument()
    expect(
      view.getByText('edited 10 hours ago by Jane Doe'),
    ).toBeInTheDocument()
  })

  it('renders when something is missing', () => {
    const user: UserItemData = {
      id: '123',
      ticketsCount: {
        open: 1,
        closed: 0,
      },
      firstname: 'John',
    }

    const view = renderComponent(UserItem, {
      props: {
        entity: user,
      },
      store: true,
    })

    expect(view.getByText('JO')).toBeInTheDocument() // avatar
    expect(view.getByText(/^John$/)).toBeInTheDocument()
    expect(view.getByText('1 ticket')).toBeInTheDocument()
    expect(view.queryByText(/·/)).not.toBeInTheDocument()
    expect(view.queryByTestId('stringUpdated')).not.toBeInTheDocument()
  })
})
