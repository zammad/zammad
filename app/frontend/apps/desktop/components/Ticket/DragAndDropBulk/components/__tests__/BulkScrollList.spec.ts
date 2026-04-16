// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { DragAndDropBulkEntityType, type BulkScrollListItem } from '../../types.ts'
import BulkScrollList from '../BulkScrollList.vue'

const groupItem: BulkScrollListItem = {
  internalId: 1,
  label: 'Support',
  type: DragAndDropBulkEntityType.Group,
}

const macroItem: BulkScrollListItem = {
  internalId: 2,
  label: 'Close ticket',
  type: DragAndDropBulkEntityType.Macro,
}

const ownerItem: BulkScrollListItem = {
  internalId: 3,
  label: 'John Doe',
  type: DragAndDropBulkEntityType.Owner,
}

const renderList = (list: BulkScrollListItem[] = []) =>
  renderComponent(BulkScrollList, { props: { list } })

describe('BulkScrollList', () => {
  describe('list rendering', () => {
    it('renders each item label', () => {
      const wrapper = renderList([groupItem, macroItem])
      expect(wrapper.getByText('Support')).toBeInTheDocument()
      expect(wrapper.getByText('Close ticket')).toBeInTheDocument()
    })

    //. We assert here to have attributes as they are required
    // to work with useBulkDragAndDrop, which relies on data attributes
    //  to identify the entity type and group association.
    it('sets the id attribute on each list item', () => {
      const wrapper = renderList([groupItem, macroItem])

      const list = wrapper.getAllByRole('listitem')
      expect(list[0]).toHaveAttribute('data-internal-id', '1') // ' Support
      expect(list[1]).toHaveAttribute('data-internal-id', '2') // ' Close ticket
    })

    it('sets the data-type attribute on each list item', () => {
      const wrapper = renderList([groupItem, macroItem])

      const list = wrapper.getAllByRole('listitem')

      expect(list[0]).toHaveAttribute('data-type', DragAndDropBulkEntityType.Group) // ' Support
      expect(list[1]).toHaveAttribute('data-type', DragAndDropBulkEntityType.Macro) // ' Close ticket
    })

    it('sets data-group-id attribute when groupId is provided', () => {
      const itemWithGroupId: BulkScrollListItem = {
        ...ownerItem,
        groupInternalId: 3,
      }
      const wrapper = renderList([itemWithGroupId])

      const list = wrapper.getAllByRole('listitem')

      expect(list[0]).toHaveAttribute('data-type', DragAndDropBulkEntityType.Owner) // ' Support
      expect(list[0]).toHaveAttribute('data-group-internal-id', '3') // ' Support
      expect(list[0]).toHaveAttribute('data-internal-id', '3') // ' Support
    })
  })

  describe('go-inside-group event', () => {
    it('renders a group item with the go-inside-group action', async () => {
      const wrapper = renderList([groupItem])

      // The arrow-down-short icon is rendered inside group cards to trigger go-inside-group
      expect(wrapper.getByIconName('arrow-down-short')).toBeInTheDocument()
    })
  })

  describe('scroll buttons', () => {
    it('does not show scroll buttons when container does not overflow', () => {
      const wrapper = renderList([macroItem])
      // In jsdom, scrollLeft=0 and scrollWidth=clientWidth=0, so no buttons shown
      expect(wrapper.queryByRole('button')).not.toBeInTheDocument()
    })

    it('shows the start scroll button when scrolled right', async () => {
      const wrapper = renderList([macroItem])
      const ul = wrapper.getByRole('list')

      Object.defineProperty(ul, 'scrollLeft', {
        value: 100,
        configurable: true,
        writable: true,
      })
      Object.defineProperty(ul, 'clientWidth', { value: 300, configurable: true })
      Object.defineProperty(ul, 'scrollWidth', { value: 600, configurable: true })

      // Trigger a scrollend event on the container, so the visibility is recalculated.
      ul.dispatchEvent(new Event('scrollend'))

      await nextTick()

      expect(wrapper.getByRole('button', { name: 'Scroll left' })).toBeInTheDocument()
    })

    it('shows the end scroll button when content overflows to the right', async () => {
      const wrapper = renderList([macroItem])
      const ul = wrapper.getByRole('list')

      Object.defineProperty(ul, 'scrollLeft', {
        value: 0,
        configurable: true,
        writable: true,
      })
      Object.defineProperty(ul, 'clientWidth', { value: 300, configurable: true })
      Object.defineProperty(ul, 'scrollWidth', { value: 600, configurable: true })

      // Trigger a scrollend event on the container, so the visibility is recalculated.
      ul.dispatchEvent(new Event('scrollend'))

      await nextTick()

      expect(wrapper.getByRole('button', { name: 'Scroll right' })).toBeInTheDocument()
    })
  })
})
