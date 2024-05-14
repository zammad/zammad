// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '#shared/i18n.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import type { MenuItem } from '#desktop/components/CommonPopover/types.ts'
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
    shallow: false,
    ...options,
    props,
  })
}

beforeEach(() => {
  i18n.setTranslationMap(new Map([['Role', 'Rolle']]))
})

describe('CommonSimpleTable.vue', () => {
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
    const view = renderTable({
      headers: tableHeaders,
      items: tableItems,
      actions: tableActions,
    })

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
})
