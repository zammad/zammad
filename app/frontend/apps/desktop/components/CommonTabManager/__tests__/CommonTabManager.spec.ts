// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { describe } from 'vitest'

import { renderComponent } from '#tests/support/components/index.ts'

import CommonTabManager from '#desktop/components/CommonTabManager/CommonTabManager.vue'

describe('CommonTabManager', () => {
  describe('single tab mode', () => {
    const tabs = [
      { label: 'Tab 1', key: 'tab-1' },
      { label: 'Tab 2', key: 'tab-2' },
      { label: 'Tab 3', key: 'tab-3' },
    ]

    it('renders CommonTabManager', () => {
      const wrapper = renderComponent(CommonTabManager, {
        props: {
          tabs,
        },
      })

      expect(wrapper.getByText('Tab 1')).toBeInTheDocument()
      expect(wrapper.getByText('Tab 2')).toBeInTheDocument()
      expect(wrapper.getByText('Tab 3')).toBeInTheDocument()
    })

    it('set by default the first tab to active', () => {
      const wrapper = renderComponent(CommonTabManager, {
        props: {
          tabs,
        },
      })

      waitFor(() => {
        expect(wrapper.getByRole('tab', { selected: true })).toHaveTextContent(
          'Tab 1',
        )
      })
    })

    it('allows setting a default active tab', () => {
      const wrapper = renderComponent(CommonTabManager, {
        props: {
          tabs: [
            ...tabs,
            {
              label: 'Tab 4',
              key: 'tab-4',
              default: true,
            },
          ],
        },
      })

      waitFor(() => {
        expect(wrapper.getByRole('tab', { selected: true })).toHaveTextContent(
          'Tab 4',
        )
      })
    })

    it('switches tab on click', async () => {
      const wrapper = renderComponent(CommonTabManager, {
        props: {
          tabs: [...tabs],
        },
      })

      await wrapper.events.click(wrapper.getByRole('tab', { name: 'Tab 2' }))

      waitFor(() => {
        expect(wrapper.getByRole('tab', { selected: true })).toHaveTextContent(
          'Tab 2',
        )
      })
    })
  })

  describe('filter mode', () => {
    const filters = [
      { label: 'Admin', key: 'admin' },
      { label: 'Agent', key: 'agent' },
      { label: 'Customer', key: 'customer' },
    ]

    it('renders CommonTabManager', () => {
      const wrapper = renderComponent(CommonTabManager, {
        props: {
          tabs: filters,
          label: 'Roles',
          multiple: true,
        },
      })
      // A11y
      expect(wrapper.getByText('Roles')).toBeInTheDocument()
      expect(wrapper.getAllByLabelText('Roles')).toHaveLength(3)

      expect(wrapper.getByText('Admin')).toBeInTheDocument()
      expect(wrapper.getByText('Agent')).toBeInTheDocument()
      expect(wrapper.getByText('Customer')).toBeInTheDocument()
    })

    it('selects two filters', async () => {
      const wrapper = renderComponent(CommonTabManager, {
        props: {
          tabs: filters,
          label: 'Roles',
          multiple: true,
        },
      })

      await wrapper.events.click(wrapper.getByText('Admin'))
      await wrapper.events.click(wrapper.getByText('Agent'))

      waitFor(() => {
        expect(wrapper.getAllByRole('option', { selected: true })).toHaveLength(
          2,
        )
      })

      await wrapper.events.click(wrapper.getByText('Admin'))

      waitFor(() => {
        expect(wrapper.getAllByRole('option', { selected: true })).toHaveLength(
          1,
        )
      })
    })
  })
})
