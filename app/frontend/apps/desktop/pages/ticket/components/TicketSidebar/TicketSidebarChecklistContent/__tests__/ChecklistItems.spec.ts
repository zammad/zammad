// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import type { ChecklistItem } from '#shared/graphql/types.ts'

import ChecklistItems from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklistContent/ChecklistItems.vue'

const items: Partial<ChecklistItem>[] = [
  {
    id: '1',
    text: 'Foo',
    checked: false,
  },
  {
    id: '2',
    text: 'Foo 2',
    checked: true,
  },
  {
    id: '3',
    text: 'Foo 3',
    checked: false,
  },
]

const renderChecklistItems = (
  items: Partial<ChecklistItem>[],
  title = 'Ticket demo title',
  readOnly = false,
) =>
  renderComponent(ChecklistItems, {
    props: { items, title, readOnly, noDefaultTitle: true },
    form: true,
    router: true,
  })

describe('ChecklistItems', () => {
  it('displays checklist content', () => {
    // Formkit Drag and Drop throws annoying warning in console
    // `The number of enabled nodes does not match the number of values.`

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

  it('displays content in readonly mode', async () => {
    const wrapper = renderChecklistItems(items, 'Ticket demo title', true)

    expect(wrapper.queryByRole('button')).not.toBeInTheDocument()

    const checkboxes = wrapper.getAllByRole('checkbox')

    checkboxes.forEach((checkbox) => {
      expect(checkbox).toHaveAttribute('aria-readonly', 'true')
    })

    await wrapper.events.click(checkboxes[0])

    expect(wrapper.emitted('set-item-checked')).toBeUndefined()
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

      expect(
        wrapper.queryByRole('button', { name: 'Action menu button' }),
      ).not.toBeInTheDocument()
    })
  })
})
