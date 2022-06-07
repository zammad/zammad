// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

const now = new Date(2022, 1, 1, 20, 0, 0, 0)
vi.setSystemTime(now)

import { renderComponent } from '@tests/support/components'
import { OrganizationItemData } from '../types'
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
      ticketsCount: 2,
      name: 'lorem ipsum',
      active: true,
      members: [
        {
          lastname: 'Wise',
          firstname: 'Erik',
        },
        {
          lastname: 'Smith',
          firstname: 'Peter',
        },
        {
          lastname: "O'Hara",
          firstname: 'Nils',
        },
      ],
      updatedAt: new Date(2022, 1, 1, 10, 0, 0, 0).toISOString(),
      updatedBy: {
        id: '456',
        firstname: 'Jane',
        lastname: 'Doe',
      },
    }

    const view = renderComponent(OrganizationItem, {
      props: {
        entity: organization,
      },
      store: true,
    })

    expect(view.getByText('lorem ipsum')).toBeInTheDocument()
    expect(view.getByText('2 tickets')).toBeInTheDocument()
    expect(view.getByText('·')).toBeInTheDocument()
    expect(view.getByText('Erik Wise, Peter Smith, +1')).toBeInTheDocument()

    expect(
      view.getByText('edited 10 hours ago by Jane Doe'),
    ).toBeInTheDocument()
  })

  it('renders when something is missing', () => {
    const organization: OrganizationItemData = {
      id: '54321',
      ticketsCount: 1,
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
    expect(view.getByText('1 ticket')).toBeInTheDocument()
    expect(view.queryIconByName('·')).not.toBeInTheDocument()

    expect(view.queryByTestId('stringUpdated')).not.toBeInTheDocument()
  })
})
