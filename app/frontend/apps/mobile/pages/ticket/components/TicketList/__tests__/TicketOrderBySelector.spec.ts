// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { SelectOption } from '@shared/components/Form/fields/FieldSelect'
import { within } from '@testing-library/vue'
import { renderComponent } from '@tests/support/components'
import TicketOrderBySelector from '../TicketOrderBySelector.vue'

const columns: SelectOption[] = [
  {
    value: 'title',
    label: 'Title',
  },
  {
    value: 'updated_at',
    label: 'Updated at',
  },
]

describe('testing "order by" selector for ticket list', () => {
  it('can traverse column and direction options', async () => {
    const view = renderComponent(TicketOrderBySelector, {
      props: {
        options: columns,
        label: 'Title',
      },
    })

    const button = view.getByRole('button', {
      name: 'Tickets are ordered by "Title" column (descending).',
    })

    expect(button).toBeInTheDocument()
    expect(view.queryByRole('dialog')).not.toBeInTheDocument()

    await view.events.click(button)

    const dialog = view.getByRole('dialog')
    const queries = within(dialog)

    await view.events.keyboard('{ArrowDown}')

    expect(queries.getByRole('option', { name: 'Updated at' })).toHaveFocus()

    await view.events.keyboard('{ArrowDown}')

    expect(queries.getByRole('button', { name: 'descending' })).toHaveFocus()

    await view.events.keyboard('{ArrowDown}')

    expect(queries.getByRole('option', { name: 'Title' })).toHaveFocus()

    await view.events.keyboard('{ArrowUp}')

    expect(queries.getByRole('button', { name: 'ascending' })).toHaveFocus()

    await view.events.keyboard('{ArrowLeft}')

    expect(queries.getByRole('button', { name: 'descending' })).toHaveFocus()

    await view.events.keyboard('{ArrowLeft}')

    expect(queries.getByRole('button', { name: 'ascending' })).toHaveFocus()

    await view.events.keyboard('{ArrowRight}')

    expect(queries.getByRole('button', { name: 'descending' })).toHaveFocus()

    await view.events.keyboard('{ArrowRight}')

    expect(queries.getByRole('button', { name: 'ascending' })).toHaveFocus()
  })

  it('returns focus, when closed', async () => {
    const view = renderComponent(TicketOrderBySelector, {
      props: {
        options: columns,
        label: 'Title',
      },
    })

    const button = view.getByRole('button', {
      name: 'Tickets are ordered by "Title" column (descending).',
    })

    await view.events.click(button)

    expect(button).not.toHaveFocus()

    await view.events.keyboard('{Escape}')

    expect(button).toHaveFocus()
  })
})
