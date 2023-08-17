// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketItemData } from '../types.ts'

const now = new Date(2022, 1, 1, 20, 0, 0, 0)
vi.setSystemTime(now)

const { TicketState } = await import('#shared/entities/ticket/types.ts')
const { EnumTicketStateColorCode } = await import('#shared/graphql/types.ts')
const { default: TicketItem } = await import('../TicketItem.vue')
const { renderComponent } = await import('#tests/support/components/index.ts')

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
    expect(view.getByIconName('mobile-check-circle-no')).toHaveAccessibleName(
      '(state: open)',
    )

    expect(view.getByText('#12345 · John Doe')).toBeInTheDocument()
    expect(view.getByText('test ticket')).toBeInTheDocument()

    expect(
      view.getByText('edited 10 hours ago by Jane Doe'),
    ).toBeInTheDocument()

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
    expect(view.getByIconName('mobile-check-circle-no')).toHaveAccessibleName(
      '(state: open)',
    )

    expect(view.getByText('#12345')).toBeInTheDocument()
    expect(view.queryByText(/·/)).not.toBeInTheDocument()
    expect(view.getByText('test ticket')).toBeInTheDocument()

    expect(view.queryByTestId('stringUpdated')).not.toBeInTheDocument()
    expect(view.queryByText('3 high')).not.toBeInTheDocument()
  })
})
