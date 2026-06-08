// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { merge } from 'lodash-es'
import { ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { EnumOrderDirection } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TableHeader from '../TableHeader.vue'

import type { TableAdvancedItem, TableAttribute } from '../types.ts'

const tableAttributes: TableAttribute[] = [
  {
    name: 'title',
    label: 'Title',
    headerPreferences: {},
    columnPreferences: {},
    dataOption: {},
    dataType: 'input',
  },
  {
    name: 'state',
    label: 'State',
    headerPreferences: {},
    columnPreferences: {},
    dataOption: {},
    dataType: 'select',
  },
]

const tableItems: TableAdvancedItem[] = [
  {
    id: convertToGraphQLId('Ticket', 1),
    title: 'Ticket 1',
    state: 'open',
  },
  {
    id: convertToGraphQLId('Ticket', 2),
    title: 'Ticket 2',
    state: 'closed',
  },
  {
    id: convertToGraphQLId('Ticket', 3),
    title: 'Ticket 3',
    state: 'pending',
  },
]

const renderTableHeader = (props: Partial<InstanceType<typeof TableHeader>['$props']> = {}) => {
  const selectAllLoadedActive = ref(false)

  const mergedProps = merge(
    {
      items: tableItems,
      itemIds: new Set<string>(),
      tableAttributes,
      hasBulkAction: true,
      selectedCount: 0,
      totalItemsCount: 10,
      maxItems: 1000,
    },
    props,
  )

  const wrapper = renderComponent(TableHeader, {
    props: mergedProps,
    vModel: { selectAllLoadedActive },
  })

  return { wrapper, selectAllLoadedActive }
}

describe('TableHeader.vue', () => {
  describe('bulk selection - showAll functionality', () => {
    it('shows select all loaded items action when items are selected', async () => {
      const itemIds = new Set([tableItems[0].id])

      const { wrapper } = renderTableHeader({ itemIds })

      await waitForNextTick()

      expect(wrapper.queryByText('1 results selected')).not.toBeInTheDocument()

      const bulkCheckbox = wrapper.getByRole('checkbox', {
        name: 'Select all entries',
      })

      await wrapper.events.click(bulkCheckbox)

      expect(wrapper.emitted('select-all-loaded')).toBeTruthy()
    })

    it('emits select-all event when "Select all results" button is clicked', async () => {
      const itemIds = new Set([tableItems[0].id, tableItems[1].id])

      const { wrapper, selectAllLoadedActive } = renderTableHeader({
        itemIds,
        selectedCount: 2,
      })

      await waitForNextTick()

      const bulkCheckbox = wrapper.getByRole('checkbox', { name: 'Select all entries' })
      await wrapper.events.click(bulkCheckbox)

      selectAllLoadedActive.value = true
      await wrapper.rerender({
        itemIds: new Set([tableItems[0].id, tableItems[1].id, tableItems[2].id]),
        selectedCount: 3,
      })

      await waitForNextTick()

      const selectAllButton = await waitFor(() =>
        wrapper.getByRole('button', {
          name: 'Select all 10 results',
        }),
      )
      await wrapper.events.click(selectAllButton)

      expect(wrapper.emitted('select-all')).toBeTruthy()
    })

    it('shows "Clear selection" button after selecting all items (when not all loaded)', async () => {
      const itemIds = new Set([tableItems[0].id, tableItems[1].id])

      const { wrapper, selectAllLoadedActive } = renderTableHeader({
        itemIds,
        selectedCount: 2,
      })

      await waitForNextTick()

      // Step 1: Select all loaded
      const bulkCheckbox = wrapper.getByRole('checkbox')
      await wrapper.events.click(bulkCheckbox)

      // Update to reflect all loaded items selected
      selectAllLoadedActive.value = true
      await wrapper.rerender({
        itemIds: new Set([tableItems[0].id, tableItems[1].id, tableItems[2].id]),
        selectedCount: 3,
      })

      await waitForNextTick()

      // Select all (including unloaded)
      const selectAllButton = await waitFor(() =>
        wrapper.getByRole('button', {
          name: 'Select all 10 results',
        }),
      )
      await wrapper.events.click(selectAllButton)

      await waitForNextTick()

      await waitFor(() => {
        expect(
          wrapper.queryByRole('button', { name: 'Select all 10 results' }),
        ).not.toBeInTheDocument()
      })

      expect(wrapper.getByRole('button', { name: 'Clear selection' })).toBeInTheDocument()
    })

    it('emits deselect-all event when user cancels select-all operation', async () => {
      const itemIds = new Set([tableItems[0].id, tableItems[1].id])

      const { wrapper, selectAllLoadedActive } = renderTableHeader({
        itemIds,
        selectedCount: 2,
      })

      await waitForNextTick()

      const bulkCheckbox = wrapper.getByRole('checkbox', { name: 'Select all entries' })
      await wrapper.events.click(bulkCheckbox)

      selectAllLoadedActive.value = true
      await wrapper.rerender({
        itemIds: new Set([tableItems[0].id, tableItems[1].id, tableItems[2].id]),
        selectedCount: 3,
      })

      await waitForNextTick()

      const selectAllButton = await waitFor(() =>
        wrapper.getByRole('button', {
          name: 'Select all 10 results',
        }),
      )
      await wrapper.events.click(selectAllButton)

      await waitForNextTick()

      const deselectAllButton = await waitFor(() =>
        wrapper.getByRole('button', {
          name: 'Clear selection',
        }),
      )

      await wrapper.events.click(deselectAllButton)

      expect(wrapper.emitted('deselect-all')).toBeTruthy()
    })

    it('does not show meta header when all items are already loaded', async () => {
      const itemIds = new Set([tableItems[0].id, tableItems[1].id])

      const { wrapper, selectAllLoadedActive } = renderTableHeader({
        itemIds,
        selectedCount: 2,
        totalItemsCount: 3,
      })

      await waitForNextTick()

      const bulkCheckbox = wrapper.getByRole('checkbox')
      await wrapper.events.click(bulkCheckbox)

      selectAllLoadedActive.value = true

      await wrapper.rerender({
        itemIds: new Set([tableItems[0].id, tableItems[1].id, tableItems[2].id]),
        selectedCount: 3,
        totalItemsCount: 3,
      })

      await waitForNextTick()

      expect(wrapper.queryByTestId('tableMetaHeader')).not.toBeInTheDocument()
    })

    it('resets selectAllActive state when deselecting', async () => {
      const itemIds = new Set([tableItems[0].id, tableItems[1].id])

      const { wrapper, selectAllLoadedActive } = renderTableHeader({
        itemIds,
        selectedCount: 2,
      })

      await waitForNextTick()

      const bulkCheckbox = wrapper.getByRole('checkbox')
      await wrapper.events.click(bulkCheckbox)

      selectAllLoadedActive.value = true
      await wrapper.rerender({
        itemIds: new Set([tableItems[0].id, tableItems[1].id, tableItems[2].id]),
        selectedCount: 3,
      })

      await waitForNextTick()

      const selectAllButton = await waitFor(() =>
        wrapper.getByRole('button', {
          name: 'Select all 10 results',
        }),
      )
      await wrapper.events.click(selectAllButton)

      await waitForNextTick()

      const deselectButton = await waitFor(() =>
        wrapper.getByRole('button', {
          name: 'Clear selection',
        }),
      )
      await wrapper.events.click(deselectButton)

      expect(wrapper.emitted('deselect-all')).toBeTruthy()

      selectAllLoadedActive.value = false
      await wrapper.rerender({
        itemIds: new Set(),
        selectedCount: 0,
      })

      await waitForNextTick()

      // Meta row should be hidden
      expect(wrapper.queryByTestId('tableMetaHeader')).not.toBeInTheDocument()
    })

    it('displays "All results selected" message when select-all is active', async () => {
      const { wrapper, selectAllLoadedActive } = renderTableHeader({
        itemIds: new Set([tableItems[0].id]),
        selectedCount: 1,
      })

      await waitForNextTick()

      // First click the bulk checkbox to show the meta row
      const bulkCheckbox = wrapper.getByRole('checkbox', {
        name: 'Select all entries',
      })
      await wrapper.events.click(bulkCheckbox)

      selectAllLoadedActive.value = true

      await waitForNextTick()

      // All loaded items are selected, so the action to select all results is available.
      await wrapper.rerender({
        itemIds: new Set([tableItems[0].id, tableItems[1].id, tableItems[2].id]),
        selectedCount: 3,
      })

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Select all 10 results' }))

      await waitForNextTick()

      expect(wrapper.getByText('All 10 result(s) selected')).toBeInTheDocument()
    })
  })

  describe('sorting functionality', () => {
    it('emits sort event when clicking on sortable header', async () => {
      const { wrapper } = renderTableHeader({
        orderBy: 'title',
        orderDirection: EnumOrderDirection.Ascending,
        hasBulkAction: false,
      })

      await waitForNextTick()

      const sortButton = wrapper.getByRole('button', {
        name: 'Sort by Title descending',
      })

      await wrapper.events.click(sortButton)

      expect(wrapper.emitted('sort')).toBeTruthy()
      expect(wrapper.emitted('sort')?.[0]).toEqual(['title'])
    })

    it('displays correct sort icon based on direction', async () => {
      const { wrapper } = renderTableHeader({
        orderBy: 'title',
        orderDirection: EnumOrderDirection.Ascending,
        hasBulkAction: false,
      })

      await waitForNextTick()

      let headerButton = await wrapper.findByRole('button', {
        name: 'Sort by Title descending',
      })

      expect(headerButton).toBeVisible()

      await wrapper.rerender({
        orderBy: 'title',
        orderDirection: EnumOrderDirection.Descending,
      })

      await waitForNextTick()

      headerButton = await wrapper.findByRole('button', {
        name: 'Sort by Title ascending',
      })

      expect(headerButton).toBeVisible()
    })
  })

  describe('column headers', () => {
    it('renders all table attribute headers', async () => {
      const { wrapper } = renderTableHeader({ hasBulkAction: false })

      await waitForNextTick()

      expect(wrapper.getByText('Title')).toBeInTheDocument()
      expect(wrapper.getByText('State')).toBeInTheDocument()
    })

    it('renders actions column when actions are provided', async () => {
      const { wrapper } = renderTableHeader({
        hasBulkAction: false,
        actions: [{ key: 'delete', label: 'Delete' }],
      })

      await waitForNextTick()

      expect(wrapper.getByText('Actions')).toBeInTheDocument()
    })

    it('does not render actions column when no actions provided', async () => {
      const { wrapper } = renderTableHeader({ hasBulkAction: false })

      await waitForNextTick()

      expect(wrapper.queryByText('Actions')).not.toBeInTheDocument()
    })
  })
})
