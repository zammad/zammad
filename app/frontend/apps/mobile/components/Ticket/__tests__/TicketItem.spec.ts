// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { TicketState } from '#shared/entities/ticket/types.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumTicketStateColorCode } from '#shared/graphql/types.ts'

import TicketItem from '../TicketItem.vue'

import type { TicketItemData } from '../types.ts'

vi.hoisted(() => {
  const now = new Date(2022, 1, 1, 20, 0, 0, 0)
  vi.setSystemTime(now)
})

describe('ticket item display', () => {
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
        name: '3 high',
        uiColor: 'high-priority',
        defaultCreate: false,
      },
      stateColorCode: EnumTicketStateColorCode.Open,
    }

    const view = renderComponent(TicketItem, {
      props: {
        entity: ticket,
      },
      store: true,
      router: true,
    })

    expect(view.getByRole('group')).toHaveClass('text-yellow')
    expect(view.getByIconName('check-circle-no')).toHaveAccessibleName('(state: open)')

    expect(view.getByText('#12345 · John Doe')).toBeInTheDocument()
    expect(view.getByText('test ticket')).toBeInTheDocument()

    expect(view.getByText('edited 10 hours ago by Jane Doe')).toBeInTheDocument()

    const priority = view.getByText('3 high')

    expect(priority).toBeInTheDocument()
    expect(priority).toHaveClasses(['bg-red-dark', 'text-red-bright'])
  })

  it('renders when something is missing', () => {
    const ticket: TicketItemData = {
      id: '54321',
      number: '12345',
      internalId: 1,
      state: { name: TicketState.Open },
      title: 'test ticket',
      stateColorCode: EnumTicketStateColorCode.Open,
    }

    const view = renderComponent(TicketItem, {
      props: {
        entity: ticket,
      },
      store: true,
      router: true,
    })

    expect(view.getByRole('group')).toHaveClass('text-yellow')
    expect(view.getByIconName('check-circle-no')).toHaveAccessibleName('(state: open)')

    expect(view.getByText('#12345')).toBeInTheDocument()
    expect(view.queryByText(/·/)).not.toBeInTheDocument()
    expect(view.getByText('test ticket')).toBeInTheDocument()

    expect(view.queryByTestId('stringUpdated')).not.toBeInTheDocument()
    expect(view.queryByText('3 high')).not.toBeInTheDocument()
  })

  describe('Ai Agent', () => {
    it('shows ai agent indicator if running', () => {
      const view = renderComponent(TicketItem, {
        props: {
          entity: createDummyTicket({ aiAgentRunning: true }),
        },
        store: true,
        router: true,
      })

      expect(view.getByIconName('check-circle-no-ai')).toHaveAttribute(
        'aria-label',
        'Currently processing this ticket…',
      )
    })
  })
})
