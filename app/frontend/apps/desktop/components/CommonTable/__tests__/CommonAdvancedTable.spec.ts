// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { faker } from '@faker-js/faker'
import { waitFor, within } from '@testing-library/vue'
import { vi } from 'vitest'
import { ref } from 'vue'

import ticketObjectAttributes from '#tests/graphql/factories/fixtures/ticket-object-attributes.ts'
import { type ExtendedMountingOptions, renderComponent } from '#tests/support/components/index.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumObjectManagerObjects, EnumOrderDirection } from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { i18n } from '#shared/i18n.ts'
import type { ObjectWithId } from '#shared/types/utils.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

import CommonAdvancedTable from '../CommonAdvancedTable.vue'

import type { AdvancedTableProps, TableAdvancedItem } from '../types.ts'

mockRouterHooks()

const tableHeaders = ['title', 'owner', 'state', 'priority', 'created_at']

const tableItems: TableAdvancedItem[] = [
  {
    id: convertToGraphQLId('Ticket', 1),
    title: 'Dummy ticket',
    owner: {
      __typename: 'User',
      id: convertToGraphQLId('User', 1),
      internalId: 2,
      firstname: 'Agent 1',
      lastname: 'Test',
      fullname: 'Agent 1 Test',
    },
    state: {
      __typename: 'TicketState',
      id: convertToGraphQLId('TicketState', 1),
      name: 'open',
    },
    priority: {
      __typename: 'TicketPriority',
      id: convertToGraphQLId('TicketPriority', 3),
      name: '3 high',
    },
    created_at: '2021-01-01T12:00:00Z',
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

vi.mock('@vueuse/core', async (importOriginal) => {
  const modules = await importOriginal<typeof import('@vueuse/core')>()
  return {
    ...modules,
    useInfiniteScroll: (scrollContainer: HTMLElement, callback: () => Promise<void>) => {
      callback()
      return { reset: vi.fn(), isLoading: ref(false) }
    },
  }
})

const renderTable = async (
  props: AdvancedTableProps,
  options: ExtendedMountingOptions<AdvancedTableProps> = {},
) => {
  const wrapper = renderComponent(CommonAdvancedTable, {
    router: true,
    form: true,
    store: true,
    ...options,
    props: {
      object: EnumObjectManagerObjects.Ticket,
      ...props,
    },
  })

  await waitForNextTick()

  return wrapper
}

beforeEach(() => {
  mockObjectManagerFrontendAttributesQuery({
    objectManagerFrontendAttributes: ticketObjectAttributes(),
  })

  i18n.setTranslationMap(new Map([['Priority', 'Wichtigkeit']]))
})

describe('CommonAdvancedTable', () => {
  it('displays the table without actions', async () => {
    const wrapper = await renderTable({
      headers: tableHeaders,
      items: tableItems,
      totalItemsCount: 100,
      caption: 'Table caption',
    })

    expect(wrapper.getByText('Title')).toBeInTheDocument()
    expect(wrapper.getByText('Owner')).toBeInTheDocument()
    expect(wrapper.getByText('Wichtigkeit')).toBeInTheDocument()
    expect(wrapper.getByText('State')).toBeInTheDocument()

    expect(wrapper.getByText('Dummy ticket')).toBeInTheDocument()
    expect(wrapper.getByText('Agent 1 Test')).toBeInTheDocument()
    expect(wrapper.getByText('open')).toBeInTheDocument()
    expect(wrapper.getByText('3 high')).toBeInTheDocument()
    expect(wrapper.queryByText('Actions')).toBeNull()
  })

  it('displays the table with actions', async () => {
    const wrapper = await renderTable(
      {
        headers: tableHeaders,
        items: tableItems,
        totalItemsCount: 100,
        actions: tableActions,
        caption: 'Table caption',
      },
      {
        router: true,
        form: true,
      },
    )

    expect(wrapper.getByText('Actions')).toBeInTheDocument()
    expect(wrapper.getByLabelText('Action menu button')).toBeInTheDocument()
  })

  it('displays the additional data with the item suffix slot', async () => {
    const wrapper = await renderTable(
      {
        headers: tableHeaders,
        items: tableItems,
        totalItemsCount: 100,
        actions: tableActions,
        caption: 'Table caption',
      },
      {
        router: true,
        form: true,
        slots: {
          'item-suffix-title': '<span>Additional Example</span>',
        },
      },
    )

    expect(wrapper.getByText('Additional Example')).toBeInTheDocument()
  })

  it('generates expected DOM', async () => {
    // TODO: check if such snapshot test is really the way we want to go.
    const view = await renderTable(
      {
        headers: tableHeaders,
        items: tableItems,
        totalItemsCount: 100,
        actions: tableActions,
        caption: 'Table caption',
      },
      // NB: Please don't remove this, otherwise snapshot would contain markup of many more components other than the
      //   one under the test, which can lead to false positives.
      {
        shallow: true,
        form: true,
      },
    )

    await expect(view.getByRole('table')).toMatchFileSnapshot(`${__filename}.snapshot.txt`)
  })

  it('exposes a column tooltip via columnPreferences.tooltip', async () => {
    const wrapper = await renderTable({
      headers: [...tableHeaders, 'with_tooltip', 'without_tooltip'],
      attributes: [
        {
          name: 'with_tooltip',
          label: 'With Tooltip',
          headerPreferences: {},
          columnPreferences: {
            tooltip: (item) => item.with_tooltip as string,
          },
          dataOption: {
            type: 'text',
          },
          dataType: 'input',
        },
        {
          name: 'without_tooltip',
          label: 'Without Tooltip',
          headerPreferences: {},
          columnPreferences: {},
          dataOption: {
            type: 'text',
          },
          dataType: 'input',
        },
      ],
      items: [
        ...tableItems,
        {
          id: convertToGraphQLId('Ticket', 2),
          name: 'Max Mustermann',
          role: 'Admin',
          with_tooltip: 'Tooltip-enabled cell text',
          without_tooltip: 'Cell text without tooltip',
        },
      ],
      totalItemsCount: 100,
      caption: 'Table caption',
    })

    const withTooltip = wrapper.getByText('Tooltip-enabled cell text')

    expect(withTooltip).toHaveAttribute('data-tooltip', 'true')
    expect(withTooltip).toHaveAttribute('aria-label', 'Tooltip-enabled cell text')

    const withoutTooltip = wrapper.getByText('Cell text without tooltip')

    expect(withoutTooltip).not.toHaveAttribute('data-tooltip')
  })

  it('supports header slot', async () => {
    const wrapper = await renderTable(
      {
        headers: tableHeaders,
        items: tableItems,
        actions: tableActions,
        totalItemsCount: 100,
        caption: 'Table caption',
      },
      {
        form: true,
        slots: {
          'column-header-title': '<div>Custom header</div>',
        },
      },
    )

    expect(wrapper.getByText('Custom header')).toBeInTheDocument()
  })

  it('supports listening for row click events', async () => {
    const mockedCallback = vi.fn()

    const item = tableItems[0]

    const wrapper = renderComponent(
      {
        components: { CommonAdvancedTable },
        setup() {
          return {
            mockedCallback,
            tableHeaders,
            attributes: [
              {
                name: 'title',
                label: 'Title',
                headerPreferences: {},
                columnPreferences: {},
                dataOption: {},
                dataType: 'input',
              },
            ],
            items: [item],
          }
        },
        template: `
          <CommonAdvancedTable @click-row="mockedCallback" :headers="tableHeaders" :attributes="attributes"
                               :items="items" :total-items-count="100" caption="Table caption" />`,
      },
      { form: true },
    )

    await waitForNextTick()

    await wrapper.events.click(wrapper.getByText('Dummy ticket'))

    expect(mockedCallback).toHaveBeenCalledWith(item)

    mockedCallback.mockClear()

    wrapper.getByRole('row', { description: 'Select table row' }).focus()

    await wrapper.events.keyboard('{enter}')

    expect(mockedCallback).toHaveBeenCalledWith(item)
  })

  it('supports marking row in active color', async () => {
    const wrapper = await renderTable({
      headers: tableHeaders,
      selectedRowId: '2',
      items: [
        {
          id: '2',
          name: 'foo',
        },
      ],
      totalItemsCount: 100,
      caption: 'Table caption',
    })

    const row = wrapper.getByTestId('table-row')

    expect(row).toHaveClass('bg-blue-800!')

    expect(within(row).getAllByRole('cell')[1].children[0].children[0]).toHaveClass(
      'text-black! dark:text-white!',
    )
  })

  it('supports adding class to table header', async () => {
    const wrapper = await renderTable({
      headers: ['name'],
      attributes: [
        {
          name: 'name',
          label: 'Awesome Cell Header',
          headerPreferences: {
            labelClass: 'text-red-500 font-bold',
          },
          columnPreferences: {},
          dataOption: {
            type: 'text',
          },
          dataType: 'input',
        },
      ],
      items: [],
      totalItemsCount: 100,
      caption: 'Table caption',
    })

    expect(wrapper.getByText('Awesome Cell Header')).toHaveClass('text-red-500 font-bold')
  })

  it('supports adding a link to a cell', async () => {
    const wrapper = await renderTable(
      {
        headers: ['title'],
        attributeExtensions: {
          title: {
            columnPreferences: {
              link: {
                internal: true,
                getLink: (item: ObjectWithId) => `/tickets/${getIdFromGraphQLId(item.id)}`,
              },
            },
          },
        },
        items: [tableItems[0]],
        totalItemsCount: 100,
        caption: 'Table caption',
      },
      {
        form: true,
        router: true,
      },
    )

    const linkCell = wrapper.getByRole('link')

    expect(linkCell).toHaveTextContent('Dummy ticket')
    expect(linkCell).toHaveAttribute('href', '/desktop/tickets/1')
    expect(linkCell).not.toHaveAttribute('target')
  })

  it('supports selecting a row', async () => {
    const checkedItemIds = ref(new Set())

    const items = [
      {
        id: convertToGraphQLId('Ticket', 1),
        label: 'selection data 1',
      },
      {
        id: convertToGraphQLId('Ticket', 2),
        label: 'selection data 2',
      },
    ]

    const wrapper = await renderTable(
      {
        headers: ['label'],
        items,
        hasBulkAction: true,
        totalItemsCount: 100,
        caption: 'Table caption',
      },
      { form: true, vModel: { checkedItemIds } },
    )

    const tbody = wrapper.getAllByRole('rowgroup')[1]

    const checkboxes = within(tbody).getAllByRole('checkbox')

    expect(checkboxes).toHaveLength(2)

    const rowCheckboxes = wrapper.getAllByRole('checkbox', {
      name: 'Select this entry',
    })

    expect(rowCheckboxes[0]).not.toBeChecked()
    await wrapper.events.click(rowCheckboxes[0])
    expect(rowCheckboxes[0]).toBeChecked()

    await wrapper.events.click(rowCheckboxes[1])

    await waitFor(() => expect(Array.from(checkedItemIds.value.keys())).toContain(items[0].id))

    await waitFor(() => expect(rowCheckboxes[0]).not.toHaveAttribute('checked'))
    expect(rowCheckboxes[1]).not.toHaveAttribute('checked')

    await wrapper.events.click(rowCheckboxes[1])

    expect(await wrapper.findByLabelText('Deselect this entry')).toBeInTheDocument()
  })

  it('supports multi-selecting rows', async () => {
    const checkedItemIds = ref(new Set())

    const items = [
      {
        id: convertToGraphQLId('Ticket', 1),
        label: 'selection data 1',
      },
      {
        id: convertToGraphQLId('Ticket', 2),
        label: 'selection data 2',
      },
      {
        id: convertToGraphQLId('Ticket', 3),
        label: 'selection data 3',
      },
    ]

    const wrapper = await renderTable(
      {
        headers: ['label'],
        items,
        hasBulkAction: true,
        totalItemsCount: 100,
        caption: 'Table caption',
      },
      { form: true, vModel: { checkedItemIds } },
    )

    let rowCheckboxes = wrapper.getAllByRole('checkbox', {
      name: 'Select this entry',
    })

    // Select first item.
    await wrapper.events.click(rowCheckboxes[0])

    // Press Shift key, select third item and release Shift key to select all items in between.
    //   https://testing-library.com/docs/user-event/keyboard/
    await wrapper.events.keyboard('{Shift>}')
    await wrapper.events.click(rowCheckboxes[2])
    await wrapper.events.keyboard('{/Shift}')

    await waitFor(() => {
      expect(Array.from(checkedItemIds.value.keys())).toEqual(items.map((i) => i.id))
    })

    rowCheckboxes = wrapper.getAllByRole('checkbox', {
      name: 'Deselect this entry',
    })

    // Deselect third item.
    await wrapper.events.click(rowCheckboxes[2])

    // Press Shift key, select first item and release Shift key to deselect all items in between.
    //   https://testing-library.com/docs/user-event/keyboard/
    await wrapper.events.keyboard('{Shift>}')
    await wrapper.events.click(rowCheckboxes[0])
    await wrapper.events.keyboard('{/Shift}')

    await waitFor(() => {
      expect(Array.from(checkedItemIds.value.keys())).toEqual([])
    })
  })

  describe('auto-select with deselection tracking', () => {
    it('tracks deselected items when auto-select is active', async () => {
      const checkedItemIds = ref(new Set())

      const items = [
        {
          id: convertToGraphQLId('Ticket', 1),
          label: 'selection data 1',
        },
        {
          id: convertToGraphQLId('Ticket', 2),
          label: 'selection data 2',
        },
        {
          id: convertToGraphQLId('Ticket', 3),
          label: 'selection data 3',
        },
      ]

      const wrapper = await renderTable(
        {
          headers: ['label'],
          items,
          hasBulkAction: true,
          totalItemsCount: 100,
          caption: 'Table caption',
        },
        { form: true, vModel: { checkedItemIds } },
      )

      const selectAllButton = wrapper.getByRole('checkbox', {
        name: 'Select all entries',
      })

      await wrapper.events.click(selectAllButton)

      // Now deselect one item
      const rowCheckboxes = wrapper.getAllByRole('checkbox', {
        name: 'Deselect this entry',
      })

      await wrapper.events.click(rowCheckboxes[0])

      // The deselected item should be removed from selectedItemIds
      // but the count should consider it as deselected from the total
      await waitFor(() => {
        expect(checkedItemIds.value.has(items[0].id)).toBe(false)
      })
    })

    it('does not re-add deselected items when new items load', async () => {
      const checkedItemIds = ref(new Set())

      const initialItems = [
        {
          id: convertToGraphQLId('Ticket', 1),
          label: 'selection data 1',
        },
        {
          id: convertToGraphQLId('Ticket', 2),
          label: 'selection data 2',
        },
      ]

      const wrapper = await renderTable(
        {
          headers: ['label'],
          items: initialItems,
          hasBulkAction: true,
          totalItemsCount: 100,
          caption: 'Table caption',
        },
        { form: true, vModel: { checkedItemIds } },
      )

      const selectAllButton = wrapper.getByRole('checkbox', {
        name: 'Select all entries',
      })
      await wrapper.events.click(selectAllButton)

      await waitFor(() => {
        expect(checkedItemIds.value.size).toBe(2)
      })

      // Deselect one item
      const rowCheckboxes = wrapper.getAllByRole('checkbox', {
        name: 'Deselect this entry',
      })

      await wrapper.events.click(rowCheckboxes[0])

      await waitFor(() => {
        expect(checkedItemIds.value.size).toBe(1)
      })

      // Load more items (simulating infinite scroll)
      const newItems = [
        ...initialItems,
        {
          id: convertToGraphQLId('Ticket', 3),
          label: 'selection data 3',
        },
      ]

      await wrapper.rerender({
        headers: ['label'],
        items: newItems,
        hasBulkAction: true,
        totalItemsCount: 100,
        caption: 'Table caption',
      })

      await waitForNextTick()

      // The deselected item (item 1) should still be deselected
      // Only the new item (item 3) should be auto-selected
      expect(checkedItemIds.value.has(initialItems[0].id)).toBe(false)
    })

    it('resets auto-select state when all checked items are cleared externally', async () => {
      const checkedItemIds = ref(new Set())
      const selectAllActive = ref(false)

      const items = [
        {
          id: convertToGraphQLId('Ticket', 1),
          label: 'selection data 1',
        },
        {
          id: convertToGraphQLId('Ticket', 2),
          label: 'selection data 2',
        },
      ]

      const wrapper = await renderTable(
        {
          headers: ['label'],
          items,
          hasBulkAction: true,
          totalItemsCount: 100,
          caption: 'Table caption',
        },
        { form: true, vModel: { checkedItemIds, selectAllActive } },
      )

      const selectAllEntriesCheckbox = wrapper.getByRole('checkbox', {
        name: 'Select all entries',
      })

      await wrapper.events.click(selectAllEntriesCheckbox)

      const selectAllResultsButton = wrapper.getByRole('button', {
        name: 'Select all 100 results',
      })

      await wrapper.events.click(selectAllResultsButton)

      await waitFor(() => expect(selectAllActive.value).toBe(true))

      checkedItemIds.value = new Set()

      await waitFor(() => expect(selectAllActive.value).toBe(false))
      expect(wrapper.queryByTestId('tableMetaHeader')).not.toBeInTheDocument()
    })
  })

  it('renders disabled checkbox if update policy is not given', async () => {
    const checkedItemIds = ref(new Set())

    const items = [
      {
        id: convertToGraphQLId('Ticket', 1),
        policy: { update: false },
        label: 'selection data 1',
      },
      {
        id: convertToGraphQLId('Ticket', 2),
        label: 'selection data 2',
      },
    ]

    const wrapper = await renderTable(
      {
        headers: ['label'],
        items,
        hasBulkAction: true,
        totalItemsCount: 100,
        caption: 'Table caption',
      },
      { form: true, vModel: { checkedItemIds } },
    )

    const tbody = wrapper.getAllByRole('rowgroup')[1]

    const rowCheckboxes = within(tbody).getAllByRole('checkbox')

    expect(rowCheckboxes[0]).toBeDisabled()
  })

  it('renders disabled checkbox if item is disabled', async () => {
    const checkedItemIds = ref(new Set())

    const items = [
      {
        id: convertToGraphQLId('Ticket', 1),
        disabled: true,
        label: 'selection data 1',
      },
      {
        id: convertToGraphQLId('Ticket', 2),
        label: 'selection data 2',
      },
    ]

    const wrapper = await renderTable(
      {
        headers: ['label'],
        items,
        hasBulkAction: true,
        totalItemsCount: 100,
        caption: 'Table caption',
      },
      { form: true, vModel: { checkedItemIds } },
    )

    const tbody = wrapper.getAllByRole('rowgroup')[1]

    const rowCheckboxes = within(tbody).getAllByRole('checkbox')

    expect(rowCheckboxes[0]).toBeDisabled()
  })

  it('supports sorting', async () => {
    mockObjectManagerFrontendAttributesQuery({
      objectManagerFrontendAttributes: ticketObjectAttributes(),
    })

    const items = [
      {
        id: convertToGraphQLId('Ticket', 1),
        checked: false,
        disabled: false,
        title: 'selection data 1',
      },
    ]

    const wrapper = await renderTable({
      headers: ['title'],
      items,
      hasBulkAction: true,
      totalItemsCount: 100,
      caption: 'Table caption',
      orderBy: 'label',
    })

    const sortButton = await wrapper.findByRole('button', {
      name: 'Sort by Title ascending',
    })

    await wrapper.events.click(sortButton)

    expect(wrapper.emitted('sort').at(-1)).toEqual(['title', 'ASCENDING'])
  })

  it('supports disabling checkbox for specific rows', async () => {
    const checkedItemIds = ref(new Set())

    const items = [
      {
        id: convertToGraphQLId('Ticket', 1),
        disabled: true,
        label: 'selection data 1',
      },
      {
        id: convertToGraphQLId('Ticket', 2),
        disabled: true,
        label: 'selection data 2',
      },
    ]

    const wrapper = await renderTable(
      {
        headers: ['label'],
        items,
        hasBulkAction: true,
        totalItemsCount: 100,
        caption: 'Table caption',
      },
      { form: true, vModel: { checkedItemIds } },
    )

    const tbody = wrapper.getAllByRole('rowgroup')[1]

    const checkboxes = within(tbody).getAllByRole('checkbox')

    expect(checkboxes[1]).toBeDisabled()
    expect(checkboxes[1]).not.toBeChecked()

    expect(checkboxes[0]).toBeDisabled()
    expect(checkboxes[0]).not.toBeChecked()

    await wrapper.events.click(checkboxes[1])

    expect(checkedItemIds.value.size).toBe(0)
  })

  it('disables bulk action checkboxes when disableBulkAction is enabled', async () => {
    const checkedItemIds = ref(new Set())

    const items = [
      {
        id: convertToGraphQLId('Ticket', 1),
        label: 'selection data 1',
      },
      {
        id: convertToGraphQLId('Ticket', 2),
        label: 'selection data 2',
      },
    ]

    const wrapper = await renderTable(
      {
        headers: ['label'],
        items,
        hasBulkAction: true,
        disableBulkAction: true,
        totalItemsCount: 100,
        caption: 'Table caption',
      },
      { form: true, vModel: { checkedItemIds } },
    )

    const selectAllCheckbox = wrapper.getByRole('checkbox', {
      name: 'Select all entries',
    })

    const tbody = wrapper.getAllByRole('rowgroup')[1]

    const rowCheckboxes = within(tbody).getAllByRole('checkbox')

    expect(selectAllCheckbox).toHaveAttribute('aria-disabled', 'true')
    expect(rowCheckboxes[0]).toHaveAttribute('aria-disabled', 'true')
    expect(rowCheckboxes[1]).toHaveAttribute('aria-disabled', 'true')

    await wrapper.events.click(rowCheckboxes[0])

    expect(checkedItemIds.value.size).toBe(0)
  })

  it('clears selection when sort order changes', async () => {
    const checkedItemIds = ref(new Set())

    const items = [
      {
        id: convertToGraphQLId('Ticket', 1),
        title: 'selection data 1',
      },
      {
        id: convertToGraphQLId('Ticket', 2),
        title: 'selection data 2',
      },
    ]

    const wrapper = await renderTable(
      {
        headers: ['title'],
        items,
        hasBulkAction: true,
        totalItemsCount: 100,
        caption: 'Table caption',
        orderBy: 'title',
        orderDirection: EnumOrderDirection.Descending,
      },
      { vModel: { checkedItemIds } },
    )

    const rowCheckboxes = wrapper.getAllByRole('checkbox', {
      name: 'Select this entry',
    })

    await wrapper.events.click(rowCheckboxes[0])

    expect(checkedItemIds.value.has(items[0].id)).toBe(true)

    const sortButton = wrapper.getByRole('button', {
      name: 'Sort by Title ascending',
    })

    await wrapper.events.click(sortButton)

    await waitFor(() => expect(checkedItemIds.value.size).toBe(0))
  })

  it('informs the user about reached limits', async () => {
    const items = Array.from({ length: 30 }, () => ({
      id: convertToGraphQLId('Ticket', faker.number.int()),
      checked: false,
      disabled: false,
      title: faker.word.words(),
    }))

    const scrollContainer = document.createElement('div')
    document.body.appendChild(scrollContainer)

    const wrapper = await renderTable({
      headers: ['title'],
      items,
      hasBulkAction: true,
      totalItemsCount: 30,
      maxItems: 20,
      scrollContainer,
      caption: 'Table caption',
      orderBy: 'label',
    })

    expect(
      wrapper.getByText('You reached the table limit of 20 items (10 remaining).'),
    ).toBeInTheDocument()

    scrollContainer.remove()
  })

  it('informs the user about table end', async () => {
    const items = Array.from({ length: 30 }, () => ({
      id: convertToGraphQLId('Ticket', faker.number.int()),
      checked: false,
      disabled: false,
      title: faker.word.sample(),
    }))

    const scrollContainer = document.createElement('div')
    document.body.appendChild(scrollContainer)

    const wrapper = await renderTable({
      headers: ['title'],
      items,
      hasBulkAction: true,
      totalItemsCount: 30,
      maxItems: 30,
      scrollContainer,
      caption: 'Table caption',
      orderBy: 'label',
    })

    expect(wrapper.getByText("You don't have more items to load.")).toBeInTheDocument()

    scrollContainer.remove()
  })

  it('supports grouping and shows incomplete count', async () => {
    mockObjectManagerFrontendAttributesQuery({
      objectManagerFrontendAttributes: ticketObjectAttributes(),
    })

    const items = [
      createDummyTicket(),
      createDummyTicket({ ticketId: '2', title: faker.word.sample() }),
    ]

    const wrapper = await renderTable({
      headers: [
        'priorityIcon',
        'stateIcon',
        'title',
        'customer',
        'organization',
        'group',
        'owner',
        'state',
        'created_at',
      ],
      items,
      hasBulkAction: true,
      totalItemsCount: 30,
      maxItems: 30,
      groupBy: 'customer',
      caption: 'Table caption',
    })

    expect(wrapper.getByRole('row', { name: 'Nicole Braun2+' })).toBeInTheDocument()
  })

  it('supports grouping with object manager attributes', async () => {
    const ticketObjectAttributesPayload = ticketObjectAttributes()
    mockObjectManagerFrontendAttributesQuery({
      objectManagerFrontendAttributes: {
        ...ticketObjectAttributesPayload,
        attributes: [
          ...ticketObjectAttributesPayload.attributes,
          {
            name: 'dummy',
            display: 'dummy',
            dataType: 'input',
            dataOption: {
              default: '',
              type: 'url',
              maxlength: 120,
              null: true,
              options: {},
              relation: '',
            },
            isInternal: false,
            screens: {
              create_middle: {
                shown: true,
                required: false,
                item_class: 'column',
              },
              edit: {
                shown: true,
                required: false,
              },
            },
            __typename: 'ObjectManagerFrontendAttribute',
          },
        ],
      },
    })

    const items = [
      createDummyTicket(),
      createDummyTicket({
        ticketId: '2',
        title: faker.word.sample(),
        objectAttributeValues: [
          {
            attribute: {
              name: 'dummy',
              display: 'dummy',
            },
            value: 'grouping1',
            renderedLink: null,
          },
        ],
      }),
    ]

    const wrapper = await renderTable({
      headers: [
        'priorityIcon',
        'stateIcon',
        'title',
        'customer',
        'organization',
        'group',
        'owner',
        'state',
        'created_at',
        'dummy',
      ],
      items,
      hasBulkAction: true,
      totalItemsCount: 30,
      maxItems: 30,
      groupBy: 'dummy',
      caption: 'Table caption',
    })

    expect(wrapper.getByRole('row', { name: 'grouping11+' })).toBeInTheDocument()
  })
})
