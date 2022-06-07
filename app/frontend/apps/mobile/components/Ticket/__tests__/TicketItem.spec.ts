// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

const now = new Date(2022, 1, 1, 20, 0, 0, 0)
vi.setSystemTime(now)

import { renderComponent } from '@tests/support/components'
import { TicketState } from '@shared/entities/ticket/types'
import { TicketItemData } from '../types'
import TicketItem from '../TicketItem.vue'

describe('ticket item display', () => {
  afterEach(() => {
    vi.useRealTimers()
  })

  it('renders correctly', () => {
    const ticket: TicketItemData = {
      id: '54321',
      number: '12345',
      state: TicketState.Open,
      title: 'test ticket',
      owner: {
        firstname: 'John',
        lastname: 'Doe',
      },
      updatedAt: new Date(2022, 1, 1, 10, 0, 0, 0).toISOString(),
      updatedBy: {
        id: '456',
        firstname: 'Jane',
        lastname: 'Doe',
      },
      priority: {
        name: 'high',
        uiColor: 'high-priority',
      },
    }

    const view = renderComponent(TicketItem, {
      props: {
        entity: ticket,
      },
      store: true,
    })

    expect(view.getByAltText(TicketState.Open)).toBeInTheDocument()
    expect(view.getByText('#54321')).toBeInTheDocument()
    expect(view.getByText('·')).toBeInTheDocument()
    expect(view.getByText('John Doe')).toBeInTheDocument()
    expect(view.getByText('test ticket')).toBeInTheDocument()

    expect(
      view.getByText('edited 10 hours ago by Jane Doe'),
    ).toBeInTheDocument()

    const priority = view.getByText('HIGH')

    expect(priority).toBeInTheDocument()
    expect(priority).toHaveClass('u-high-priority-color')
  })

  it('renders when something is missing', () => {
    const ticket: TicketItemData = {
      id: '54321',
      number: '12345',
      state: TicketState.Open,
      title: 'test ticket',
    }

    const view = renderComponent(TicketItem, {
      props: {
        entity: ticket,
      },
      store: true,
    })

    expect(view.getByText('#54321')).toBeInTheDocument()
    expect(view.queryByText('·')).not.toBeInTheDocument()
    expect(view.getByText('test ticket')).toBeInTheDocument()

    expect(view.queryByTestId('stringUpdated')).not.toBeInTheDocument()

    expect(view.queryByText('HIGH')).not.toBeInTheDocument()
  })
})
