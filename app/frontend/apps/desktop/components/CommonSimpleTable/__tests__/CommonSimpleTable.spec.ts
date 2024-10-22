// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { waitFor, within } from '@testing-library/vue'
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
    const wrapper = renderTable({
      headers: tableHeaders,
      items: tableItems,
    })

    expect(wrapper.getByText('User name')).toBeInTheDocument()
    expect(wrapper.getByText('Rolle')).toBeInTheDocument()
    expect(wrapper.getByText('Lindsay Walton')).toBeInTheDocument()
    expect(wrapper.getByText('Member')).toBeInTheDocument()
    expect(wrapper.queryByText('Actions')).toBeNull()
  })

  it('displays the table with actions', async () => {
    const wrapper = renderTable(
      {
        headers: tableHeaders,
        items: tableItems,
        actions: tableActions,
      },
      { router: true },
    )

    expect(wrapper.getByText('Actions')).toBeInTheDocument()
    expect(wrapper.getByLabelText('Action menu button')).toBeInTheDocument()
  })

  it('displays the additional data with the item suffix slot', async () => {
    const wrapper = renderTable(
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

    expect(wrapper.getByText('Additional Example')).toBeInTheDocument()
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
    const wrapper = renderTable({
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

    const truncatedText = wrapper.getByText('Some text to be truncated')

    expect(truncatedText.parentElement).toHaveClass('truncate')
  })

  it('supports tooltip on truncated cell content', async () => {
    const wrapper = renderTable({
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

    await wrapper.events.hover(wrapper.getByText('Max Mustermann'))

    await waitFor(() => {
      expect(wrapper.getByText('Some text to be truncated')).toBeInTheDocument()
      expect(
        wrapper.getByLabelText('Some text to be truncated'),
      ).toBeInTheDocument()
    })
  })

  it('supports header slot', () => {
    const wrapper = renderTable(
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

    expect(wrapper.getByText('Custom header')).toBeInTheDocument()
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

    expect(mockedCallback).toHaveBeenCalledWith(item)

    wrapper.getByRole('button', { name: 'Select table row' }).focus()

    await wrapper.events.keyboard('{enter}')

    expect(mockedCallback).toHaveBeenCalledWith(item)
  })

  it('supports marking row in active color', () => {
    const wrapper = renderTable({
      headers: [
        ...tableHeaders,
        {
          key: 'name',
          label: 'name',
        },
      ],
      selectedRowId: '2',
      items: [
        {
          id: '2',
          name: 'foo',
        },
      ],
    })

    const row = wrapper.getByTestId('simple-table-row')

    expect(row).toHaveClass('!bg-blue-800')
  })

  it('supports marking row in active color', () => {
    const wrapper = renderTable({
      headers: [
        {
          key: 'name',
          label: 'name',
        },
      ],
      selectedRowId: '2',
      items: [
        {
          id: '2',
          name: 'foo cell',
        },
      ],
    })

    const row = wrapper.getByTestId('simple-table-row')

    expect(row).toHaveClass('!bg-blue-800')
    expect(within(row).getByText('foo cell')).toHaveClass(
      'text-black dark:text-white',
    )
  })

  it('supports adding class to table header', () => {
    const wrapper = renderTable({
      headers: [
        {
          key: 'name',
          label: 'Awesome Cell Header',
          labelClass: 'text-red-500 font-bold',
        },
      ],
      items: [
        {
          id: '2',
          name: 'foo cell',
        },
      ],
    })

    expect(wrapper.getByText('Awesome Cell Header')).toHaveClass(
      'text-red-500 font-bold',
    )
  })
})
