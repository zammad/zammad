// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { vi } from 'vitest'

import {
  type ExtendedMountingOptions,
  renderComponent,
} from '#tests/support/components/index.ts'

import { i18n } from '#shared/i18n.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

import CommonSimpleTable from '../CommonSimpleTable.vue'

import type { SimpleTableProps } from '../types.ts'

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
    id: '1',
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

const renderTable = (
  props: SimpleTableProps,
  options: ExtendedMountingOptions<SimpleTableProps> = { form: true },
) => {
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
      caption: 'test',
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
        caption: 'test',
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
        caption: 'test',
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
        caption: 'test',
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
      caption: 'test',
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
          id: '2',
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
      caption: 'test',
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
          id: '2',
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
        caption: 'test',
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
      template: `<CommonSimpleTable caption="Test" @click-row="mockedCallback" :headers="tableHeaders" :items="items"/>`,
    })

    await wrapper.events.click(wrapper.getByText('Lindsay Walton'))

    expect(mockedCallback).toHaveBeenCalledWith(item)

    await wrapper.events.keyboard('{enter}')

    expect(mockedCallback).toHaveBeenCalledWith(item)
  })

  it('supports adding class to table header', () => {
    const wrapper = renderTable({
      caption: 'test',
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

  it('supports adding a link to a cell', () => {
    const wrapper = renderTable(
      {
        caption: 'test',
        headers: [
          {
            key: 'urlTest',
            label: 'Link Row',
            type: 'link',
          },
        ],
        items: [
          {
            id: '1',
            urlTest: {
              label: 'Example',
              link: 'https://example.com',
              openInNewTab: true,
              external: true,
            },
          },
        ],
      },
      { router: true },
    )

    const linkCell = wrapper.getByRole('link')

    expect(linkCell).toHaveTextContent('Example')
    expect(linkCell).toHaveAttribute('href', 'https://example.com')
    expect(linkCell).toHaveAttribute('target', '_blank')
  })
})
