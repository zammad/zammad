// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

const now = new Date(2022, 1, 1, 20, 0, 0, 0)
vi.setSystemTime(now)

import { renderComponent } from '@tests/support/components'
import type { OrganizationItemData } from '../types'
import OrganizationItem from '../OrganizationItem.vue'

describe('ticket item display', () => {
  afterEach(() => {
    vi.useRealTimers()
  })

  it('renders correctly', () => {
    const now = new Date(2022, 1, 1)
    vi.setSystemTime(now)

    const organization: OrganizationItemData = {
      id: '54321',
      ticketsCount: {
        open: 2,
        closed: 1,
      },
      internalId: 3,
      name: 'lorem ipsum',
      active: true,
      members: {
        edges: [
          {
            node: { fullname: 'Erik Wise' },
          },
          {
            node: { fullname: 'Peter Smith' },
          },
        ],
        totalCount: 3,
      },
      updatedAt: new Date(2022, 1, 1, 10, 0, 0, 0).toISOString(),
      updatedBy: {
        id: '456',
        fullname: 'Jane Doe',
      },
    }

    const view = renderComponent(OrganizationItem, {
      props: {
        entity: organization,
      },
      store: true,
    })

    expect(view.getByText('lorem ipsum')).toBeInTheDocument()
    expect(view.getByText(/2 tickets/)).toBeInTheDocument()
    expect(view.getByText(/·/)).toBeInTheDocument()
    expect(view.getByText(/Erik Wise, Peter Smith, \+1/)).toBeInTheDocument()

    expect(
      view.getByText('edited 10 hours ago by Jane Doe'),
    ).toBeInTheDocument()
  })

  it('renders when something is missing', () => {
    const organization: OrganizationItemData = {
      id: '54321',
      internalId: 2,
      ticketsCount: {
        open: 1,
        closed: 0,
      },
      name: 'lorem ipsum',
      active: true,
    }

    const view = renderComponent(OrganizationItem, {
      props: {
        entity: organization,
      },
      store: true,
    })

    expect(view.getByText('lorem ipsum')).toBeInTheDocument()
    expect(view.getByText(/1 ticket/)).toBeInTheDocument()
    expect(view.queryByText(/·/)).not.toBeInTheDocument()

    expect(view.queryByTestId('stringUpdated')).not.toBeInTheDocument()
  })
})
