// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

const now = new Date(2022, 1, 1, 20, 0, 0, 0)
vi.setSystemTime(now)

import { renderComponent } from '@tests/support/components'
import { TicketState } from '@shared/entities/ticket/types'
import type { TicketItemData } from '../types'
import TicketItem from '../TicketItem.vue'

describe('ticket item display', () => {
  afterEach(() => {
    vi.useRealTimers()
  })

  it('renders correctly', () => {
    const ticket: TicketItemData = {
      id: '54321',
      number: '12345',
      internalId: 1,
      state: { name: TicketState.Open },
      title: 'test ticket',
      customer: {
        fullname: 'John Doe',
      },
      updatedAt: new Date(2022, 1, 1, 10, 0, 0, 0).toISOString(),
      updatedBy: {
        id: '456',
        fullname: 'Jane Doe',
      },
      priority: {
        name: 'high',
        uiColor: 'high-priority',
        defaultCreate: false,
      },
    }

    const view = renderComponent(TicketItem, {
      props: {
        entity: ticket,
      },
      store: true,
      router: true,
    })

    // TODO alt removed from img, maybe return? remove if error
    // expect(view.getByAltText(TicketState.Open)).toBeInTheDocument()
    expect(view.getByText('#12345 · John Doe')).toBeInTheDocument()
    // expect(view.getByText('·')).toBeInTheDocument()
    // expect(view.getByText('John Doe')).toBeInTheDocument()
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
      internalId: 1,
      state: { name: TicketState.Open },
      title: 'test ticket',
    }

    const view = renderComponent(TicketItem, {
      props: {
        entity: ticket,
      },
      store: true,
      router: true,
    })

    expect(view.getByText('#12345')).toBeInTheDocument()
    expect(view.queryByText(/·/)).not.toBeInTheDocument()
    expect(view.getByText('test ticket')).toBeInTheDocument()

    expect(view.queryByTestId('stringUpdated')).not.toBeInTheDocument()

    expect(view.queryByText('HIGH')).not.toBeInTheDocument()
  })
})
