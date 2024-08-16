// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  type ChecklistItem,
  EnumChecklistItemTicketAccess,
  EnumTicketStateColorCode,
} from '#shared/graphql/types.ts'

import ChecklistItems from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklist/TicketSidebarChecklistContent/ChecklistItems.vue'

const items: Partial<ChecklistItem>[] = [
  {
    id: '1',
    text: 'Foo',
    ticket: null,
    ticketAccess: null,
    checked: false,
  },
  {
    id: '2',
    text: 'Foo 2',
    ticket: null,
    ticketAccess: null,
    checked: true,
  },
  {
    id: '3',
    text: 'Foo 3',
    ticket: null,
    ticketAccess: null,
    checked: false,
  },
]

const renderChecklistItems = (
  items: Partial<ChecklistItem>[],
  title = 'Ticket demo title',
  readOnly = false,
) =>
  renderComponent(ChecklistItems, {
    props: {
      items,
      title,
      readOnly,
      noDefaultTitle: true,
      onEditItem: vi.fn(),
      onUpdateTitle: vi.fn(),
    },
    form: true,
    router: true,
  })

describe('ChecklistItems', () => {
  it('displays regular checklist content', () => {
    const wrapper = renderChecklistItems(items)

    // TITLE
    expect(wrapper.getByText('Ticket demo title')).toBeInTheDocument()

    // Checklist items
    expect(wrapper.getByText('Foo')).toBeInTheDocument()
    expect(wrapper.getByText('Foo 2')).toBeInTheDocument()
    expect(wrapper.getByText('Foo 3')).toBeInTheDocument()

    const checkboxes = wrapper.getAllByRole('checkbox')
    const checkboxActions = wrapper.getAllByRole('button', {
      name: 'Action menu button',
    })
    expect(checkboxes).toHaveLength(3)
    expect(checkboxActions).toHaveLength(3)

    expect(checkboxes[0]).not.toBeChecked()
    expect(checkboxes[1]).toBeChecked()
    expect(checkboxes[2]).not.toBeChecked()

    // Actions
    expect(wrapper.getByRole('button', { name: 'Reorder' }))
    expect(wrapper.getByIconName('plus-square-fill')).toBeInTheDocument()
  })

  it('displays of ticket checklist item', async () => {
    const ticket = createDummyTicket() as ChecklistItem['ticket']

    const checklistItems: Partial<ChecklistItem>[] = [
      {
        id: '1',
        text: `${ticket?.title}`,
        checked: false,
        ticket,
      },
    ]

    const wrapper = renderChecklistItems(checklistItems)

    expect(wrapper.getByText(ticket?.title as string)).toBeInTheDocument()

    expect(
      wrapper.getByRole('status', { name: 'Test Ticket' }),
    ).toBeInTheDocument()

    expect(
      wrapper.getByRole('status', { name: 'Test Ticket' }),
    ).toHaveAttribute('aria-live', 'polite')

    expect(
      wrapper.getByRole('status', { name: 'Test Ticket' }),
    ).toHaveAttribute('aria-roledescription', '(ticket status: open)')

    expect(
      wrapper.queryByRole('button', { name: 'Action menu button' }),
    ).not.toBeInTheDocument()

    expect(wrapper.queryByRole('checkbox')).not.toBeInTheDocument()

    const newTicket = createDummyTicket({
      colorCode: EnumTicketStateColorCode.Escalating,
    }) as ChecklistItem['ticket']

    const newChecklistItems: Partial<ChecklistItem>[] = [
      {
        id: '1',
        text: `${ticket?.title}`,
        checked: false,
        ticket: newTicket,
      },
    ]

    // Escalating ticket

    await wrapper.rerender({ items: newChecklistItems })

    expect(
      wrapper.getByRole('status', { name: 'Test Ticket' }),
    ).toHaveAttribute('aria-live', 'assertive')

    expect(
      wrapper.getByRole('status', { name: 'Test Ticket' }),
    ).toHaveAttribute('aria-roledescription', '(ticket status: escalating)')
  })

  it('displays denied access if authorization is not granted on linked ticket', () => {
    const ticket = createDummyTicket() as ChecklistItem['ticket']

    const checklistItems: Partial<ChecklistItem>[] = [
      {
        id: '1',
        text: `${ticket?.title}`,
        ticketAccess: EnumChecklistItemTicketAccess.Forbidden,
        checked: false,
      },
    ]

    const wrapper = renderChecklistItems(checklistItems)

    expect(wrapper.getByText('Access denied')).toBeInTheDocument()
    expect(wrapper.getByIconName('x-lg')).toBeInTheDocument()
  })

  it('displays denied access if authorization is not granted', () => {
    const ticket = createDummyTicket() as ChecklistItem['ticket']

    const checklistItems: Partial<ChecklistItem>[] = [
      {
        id: '1',
        text: `${ticket?.title}`,
        ticketAccess: EnumChecklistItemTicketAccess.Forbidden,
        checked: false,
      },
    ]

    const wrapper = renderChecklistItems(checklistItems)

    expect(wrapper.getByText('Access denied')).toBeInTheDocument()
    expect(wrapper.getByIconName('x-lg')).toBeInTheDocument()

    expect(
      wrapper.queryByLabelText('Action menu button'),
    ).not.toBeInTheDocument()

    expect(wrapper.getByLabelText('Remove item')).toBeInTheDocument()
  })

  it('displays content in readonly mode', async () => {
    const wrapper = renderChecklistItems(
      [
        ...items,
        {
          id: '2',
          text: '',
          ticket: null,
          ticketAccess: null,
          checked: false,
        },
      ],
      'Ticket demo title',
      true,
    )

    expect(wrapper.queryByRole('button')).not.toBeInTheDocument()

    const checkboxes = wrapper.getAllByRole('checkbox')

    checkboxes.forEach((checkbox) => {
      expect(checkbox).toHaveAttribute('aria-readonly', 'true')
    })

    await wrapper.events.click(checkboxes[0])

    expect(wrapper.emitted('set-item-checked')).toBeUndefined()

    expect(
      wrapper.queryByLabelText('Action menu button'),
    ).not.toBeInTheDocument()

    expect(wrapper.getByText('-')).toBeInTheDocument()
    expect(wrapper.queryByLabelText('Remove item')).not.toBeInTheDocument()
  })

  describe('features', () => {
    it('supports drag and drop', async () => {
      const wrapper = renderChecklistItems(items)

      await wrapper.events.click(
        wrapper.getByRole('button', { name: 'Reorder' }),
      )

      expect(
        wrapper.queryByRole('button', { name: 'Reorder' }),
      ).not.toBeInTheDocument()

      const dragHandles = wrapper.getAllByIconName('grip-vertical')

      expect(dragHandles).toHaveLength(3)

      expect(wrapper.getAllByRole('checkbox', { checked: true })).toHaveLength(
        1,
      )

      expect(wrapper.getAllByRole('checkbox', { checked: false })).toHaveLength(
        2,
      )

      expect(
        wrapper.queryByRole('button', { name: 'Action menu button' }),
      ).not.toBeInTheDocument()
    })
  })
})
