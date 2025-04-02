// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { faker } from '@faker-js/faker'
import { waitFor, within } from '@testing-library/vue'
import { vi } from 'vitest'
import { ref } from 'vue'

import ticketObjectAttributes from '#tests/graphql/factories/fixtures/ticket-object-attributes.ts'
import {
  type ExtendedMountingOptions,
  renderComponent,
} from '#tests/support/components/index.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockObjectManagerFrontendAttributesQuery } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'
import {
  convertToGraphQLId,
  getIdFromGraphQLId,
} from '#shared/graphql/utils.ts'
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
    useInfiniteScroll: (
      scrollContainer: HTMLElement,
      callback: () => Promise<void>,
    ) => {
      callback()
      return { reset: vi.fn(), isLoading: ref(false) }
    },
  }
})

const renderTable = async (
  props: AdvancedTableProps,
  options: ExtendedMountingOptions<AdvancedTableProps> = { form: true },
) => {
  const wrapper = renderComponent(CommonAdvancedTable, {
    router: true,
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
      totalItems: 100,
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
        totalItems: 100,
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
        totalItems: 100,
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
        totalItems: 100,
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

    await expect(view.baseElement.querySelector('table')).toMatchFileSnapshot(
      `${__filename}.snapshot.txt`,
    )
  })

  it('supports text truncation in cell content', async () => {
    const wrapper = await renderTable({
      headers: [...tableHeaders, 'truncated', 'untruncated'],
      attributes: [
        {
          name: 'truncated',
          label: 'Truncated',
          headerPreferences: {
            truncate: true,
          },
          columnPreferences: {},
          dataOption: {
            type: 'text',
          },
          dataType: 'input',
        },
        {
          name: 'untruncated',
          label: 'Untruncated',
          headerPreferences: {
            truncate: false,
          },
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
          truncated: 'Some text to be truncated',
          untruncated: 'Some text not to be truncated',
        },
      ],
      totalItems: 100,
      caption: 'Table caption',
    })

    const truncatedText = wrapper.getByText('Some text to be truncated')

    expect(truncatedText).toHaveAttribute('data-tooltip', 'true')
    expect(truncatedText.parentElement).toHaveClass('truncate')

    const untruncatedText = wrapper.getByText('Some text not to be truncated')

    expect(untruncatedText).not.toHaveAttribute('data-tooltip')
    expect(untruncatedText.parentElement).not.toHaveClass('truncate')
  })

  it('supports header slot', async () => {
    const wrapper = await renderTable(
      {
        headers: tableHeaders,
        items: tableItems,
        actions: tableActions,
        totalItems: 100,
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
                               :items="items" :total-items="100" caption="Table caption" />`,
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
      totalItems: 100,
      caption: 'Table caption',
    })

    const row = wrapper.getByTestId('table-row')

    expect(row).toHaveClass('!bg-blue-800')

    expect(within(row).getAllByRole('cell')[1].children[0]).toHaveClass(
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
      totalItems: 100,
      caption: 'Table caption',
    })

    expect(wrapper.getByText('Awesome Cell Header')).toHaveClass(
      'text-red-500 font-bold',
    )
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
                getLink: (item: ObjectWithId) =>
                  `/tickets/${getIdFromGraphQLId(item.id)}`,
              },
            },
          },
        },
        items: [tableItems[0]],
        totalItems: 100,
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

  it('supports checking a item in a row', async () => {
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
        hasCheckboxColumn: true,
        totalItems: 100,
        caption: 'Table caption',
      },
      { form: true, vModel: { checkedItemIds } },
    )

    expect(wrapper.getAllByRole('checkbox')).toHaveLength(2)

    const rowCheckboxes = wrapper.getAllByRole('checkbox', {
      name: 'Select this entry',
    })

    expect(rowCheckboxes[0]).not.toBeChecked()
    await wrapper.events.click(rowCheckboxes[0])
    expect(rowCheckboxes[0]).toBeChecked()

    await wrapper.events.click(rowCheckboxes[1])

    await waitFor(() =>
      expect(Array.from(checkedItemIds.value.keys())).toContain(items[0].id),
    )

    await waitFor(() => expect(rowCheckboxes[0]).not.toHaveAttribute('checked'))
    expect(rowCheckboxes[1]).not.toHaveAttribute('checked')

    await wrapper.events.click(rowCheckboxes[1])

    expect(
      await wrapper.findByLabelText('Deselect this entry'),
    ).toBeInTheDocument()
  })

  it('renders checklist item as disabled if update policy is not given', async () => {
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
        hasCheckboxColumn: true,
        totalItems: 100,
        caption: 'Table caption',
      },
      { form: true, vModel: { checkedItemIds } },
    )

    const rowCheckboxes = wrapper.getAllByRole('checkbox')

    expect(rowCheckboxes[0]).toBeDisabled()
  })

  it('renders checklist item as disabled', async () => {
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
        hasCheckboxColumn: true,
        totalItems: 100,
        caption: 'Table caption',
      },
      { form: true, vModel: { checkedItemIds } },
    )

    const rowCheckboxes = wrapper.getAllByRole('checkbox')

    expect(rowCheckboxes[0]).toBeDisabled()
  })

  it.todo('supports checking all items', () => {})

  it('supports disabling checkbox item for specific rows', async () => {
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
        hasCheckboxColumn: true,
        totalItems: 100,
        caption: 'Table caption',
      },
      { form: true, vModel: { checkedItemIds } },
    )

    const checkboxes = wrapper.getAllByRole('checkbox')

    expect(checkboxes[1]).toBeDisabled()
    expect(checkboxes[1]).not.toBeChecked()

    expect(checkboxes[0]).toBeDisabled()
    expect(checkboxes[0]).not.toBeChecked()

    await wrapper.events.click(checkboxes[1])

    expect(checkedItemIds.value.size).toBe(0)
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
      hasCheckboxColumn: true,
      totalItems: 100,
      caption: 'Table caption',
      orderBy: 'label',
    })

    const sortButton = await wrapper.findByRole('button', {
      name: 'Sorted descending',
    })

    await wrapper.events.click(sortButton)

    expect(wrapper.emitted('sort').at(-1)).toEqual(['title', 'ASCENDING'])
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
      hasCheckboxColumn: true,
      totalItems: 30,
      maxItems: 20,
      scrollContainer,
      caption: 'Table caption',
      orderBy: 'label',
    })

    expect(
      wrapper.getByText(
        'You reached the table limit of 20 tickets (10 remaining).',
      ),
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
      hasCheckboxColumn: true,
      totalItems: 30,
      maxItems: 30,
      scrollContainer,
      caption: 'Table caption',
      orderBy: 'label',
    })

    expect(
      wrapper.getByText("You don't have more tickets to load."),
    ).toBeInTheDocument()

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
      hasCheckboxColumn: true,
      totalItems: 30,
      maxItems: 30,
      groupBy: 'customer',
      caption: 'Table caption',
    })

    expect(
      wrapper.getByRole('row', { name: 'Nicole Braun 2+' }),
    ).toBeInTheDocument()
  })
})
