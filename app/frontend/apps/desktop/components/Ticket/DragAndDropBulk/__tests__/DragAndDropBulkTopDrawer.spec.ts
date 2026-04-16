// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import DragAndDropBulkTopDrawer from '../DragAndDropBulkTopDrawer.vue'

const macros = [
  { internalId: 1, name: 'Close ticket' },
  { internalId: 2, name: 'Assign to support' },
]

describe('DragAndDropBulkTopDrawer', () => {
  describe('loading state', () => {
    it('shows skeleton while macros are loading', () => {
      const wrapper = renderComponent(DragAndDropBulkTopDrawer, {
        props: { isActive: false, macrosLoaded: false },
      })

      expect(wrapper.getByRole('progressbar', { name: 'Content loader' })).toBeInTheDocument()
    })
  })

  describe('inactive state', () => {
    it('shows the circle "Run macro" placeholder when macros are available', () => {
      const wrapper = renderComponent(DragAndDropBulkTopDrawer, {
        props: { isActive: false, macrosLoaded: true, macros },
      })

      expect(wrapper.getByText('Run macro')).toBeInTheDocument()
    })

    it('does not show individual macro names in circle mode', () => {
      const wrapper = renderComponent(DragAndDropBulkTopDrawer, {
        props: { isActive: false, macrosLoaded: true, macros },
      })

      expect(wrapper.queryByText('Close ticket')).not.toBeInTheDocument()
      expect(wrapper.queryByText('Assign to support')).not.toBeInTheDocument()
    })
  })

  describe('active state', () => {
    it('shows individual macro names in the list', () => {
      const wrapper = renderComponent(DragAndDropBulkTopDrawer, {
        props: { isActive: true, macrosLoaded: true, macros },
      })

      expect(wrapper.getByText('Close ticket')).toBeInTheDocument()
      expect(wrapper.getByText('Assign to support')).toBeInTheDocument()
    })

    it('shows the "Run macro" heading rendered as h3', () => {
      const wrapper = renderComponent(DragAndDropBulkTopDrawer, {
        props: { isActive: true, macrosLoaded: true, macros },
      })

      const heading = wrapper.container.querySelector('h3')
      expect(heading).toBeInTheDocument()
      expect(heading?.textContent).toBe('Run macro')
    })
  })

  describe('empty state', () => {
    it('shows "No macros available" when macros array is empty', () => {
      const wrapper = renderComponent(DragAndDropBulkTopDrawer, {
        props: { isActive: false, macrosLoaded: true, macros: [] },
      })

      expect(wrapper.getByText('No macros available for selected tickets')).toBeInTheDocument()
    })

    it('shows "No macros available" when macros are undefined', () => {
      const wrapper = renderComponent(DragAndDropBulkTopDrawer, {
        props: { isActive: false, macrosLoaded: true },
      })

      expect(wrapper.getByText('No macros available for selected tickets')).toBeInTheDocument()
    })
  })
})
