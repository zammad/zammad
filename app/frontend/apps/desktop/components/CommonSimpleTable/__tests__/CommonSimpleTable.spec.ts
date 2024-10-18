// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { vi } from 'vitest'

import { renderComponent } from '#tests/support/components/index.ts'

import { i18n } from '#shared/i18n.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

import CommonSimpleTable, { type Props } from '../CommonSimpleTable.vue'

const tableHeaders = [
  {
    key: 'name',
    label: 'User name',
  },
  {
    key: 'role',
    label: 'Role',
  },
]

const tableItems = [
  {
    id: 1,
    name: 'Lindsay Walton',
    role: 'Member',
  },
]

const tableActions: MenuItem[] = [
  {
    key: 'download',
    label: 'Download this row',
    icon: 'download',
  },
  {
    key: 'delete',
    label: 'Delete this row',
    icon: 'trash3',
  },
]

const renderTable = (props: Props, options = {}) => {
  return renderComponent(CommonSimpleTable, {
    ...options,
    props,
  })
}

beforeEach(() => {
  i18n.setTranslationMap(new Map([['Role', 'Rolle']]))
})

describe('CommonSimpleTable', () => {
  it('displays the table without actions', async () => {
    const view = renderTable({
      headers: tableHeaders,
      items: tableItems,
    })

    expect(view.getByText('User name')).toBeInTheDocument()
    expect(view.getByText('Rolle')).toBeInTheDocument()
    expect(view.getByText('Lindsay Walton')).toBeInTheDocument()
    expect(view.getByText('Member')).toBeInTheDocument()
    expect(view.queryByText('Actions')).toBeNull()
  })

  it('displays the table with actions', async () => {
    const view = renderTable(
      {
        headers: tableHeaders,
        items: tableItems,
        actions: tableActions,
      },
      { router: true },
    )

    expect(view.getByText('Actions')).toBeInTheDocument()
    expect(view.getByLabelText('Action menu button')).toBeInTheDocument()
  })

  it('displays the additional data with the item suffix slot', async () => {
    const view = renderTable(
      {
        headers: tableHeaders,
        items: tableItems,
        actions: tableActions,
      },
      {
        router: true,
        slots: {
          'item-suffix-role': '<span>Additional Example</span>',
        },
      },
    )

    expect(view.getByText('Additional Example')).toBeInTheDocument()
  })

  it('generates expected DOM', async () => {
    // TODO: check if such snapshot test is really the way we want to go.
    const view = renderTable(
      {
        headers: tableHeaders,
        items: tableItems,
        actions: tableActions,
      },
      // NB: Please don't remove this, otherwise snapshot would contain markup of many more components other than the
      //   one under the test, which can lead to false positives.
      {
        shallow: true,
      },
    )

    expect(view.baseElement.querySelector('table')).toMatchFileSnapshot(
      `${__filename}.snapshot.txt`,
    )
  })

  it('supports text truncation in cell content', async () => {
    const view = renderTable({
      headers: [
        ...tableHeaders,
        {
          key: 'truncated',
          label: 'Truncated',
          truncate: true,
        },
      ],
      items: [
        ...tableItems,
        {
          id: 2,
          name: 'Max Mustermann',
          role: 'Admin',
          truncated: 'Some text to be truncated',
        },
      ],
    })

    const truncatedText = view.getByText('Some text to be truncated')

    expect(truncatedText.parentElement).toHaveClass('truncate')
  })

  it('supports tooltip on truncated cell content', async () => {
    const view = renderTable({
      headers: [
        ...tableHeaders,
        {
          key: 'truncated',
          label: 'Truncated',
          truncate: true,
        },
      ],
      items: [
        ...tableItems,
        {
          id: 2,
          name: 'Max Mustermann',
          role: 'Admin',
          truncated: 'Some text to be truncated',
        },
      ],
    })

    await view.events.hover(view.getByText('Max Mustermann'))

    await waitFor(() => {
      expect(view.getByText('Some text to be truncated')).toBeInTheDocument()
      expect(
        view.getByLabelText('Some text to be truncated'),
      ).toBeInTheDocument()
    })
  })

  it('supports header slot', () => {
    const view = renderTable(
      {
        headers: tableHeaders,
        items: tableItems,
        actions: tableActions,
      },
      {
        slots: {
          'column-header-name': '<div>Custom header</div>',
        },
      },
    )

    expect(view.getByText('Custom header')).toBeInTheDocument()
  })

  it('supports listening for row click events', async () => {
    const mockedCallback = vi.fn()

    const item = tableItems[0]
    const wrapper = renderComponent({
      components: { CommonSimpleTable },
      setup() {
        return {
          mockedCallback,
          tableHeaders,
          items: [item],
        }
      },
      template: `<CommonSimpleTable @click-row="mockedCallback" :headers="tableHeaders" :items="items"/>`,
    })

    expect(
      wrapper.getByRole('button', { name: 'Select table row' }),
    ).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByText('Lindsay Walton'))

    expect(mockedCallback).toHaveBeenCalledWith(item, expect.any(MouseEvent))

    wrapper.getByRole('button', { name: 'Select table row' }).focus()

    await wrapper.events.keyboard('{enter}')

    expect(mockedCallback).toHaveBeenCalledWith(item, expect.any(MouseEvent))
  })
})
