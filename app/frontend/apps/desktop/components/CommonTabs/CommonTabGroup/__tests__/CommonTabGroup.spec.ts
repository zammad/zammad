// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'

import CommonTabGroup from '#desktop/components/CommonTabs/CommonTabGroup/CommonTabGroup.vue'

describe('CommonTabGroup', () => {
  describe('single tab mode', () => {
    const tabs = [
      { label: 'Tab 1', key: 'tab-1' },
      { label: 'Tab 2', key: 'tab-2' },
      { label: 'Tab 3', key: 'tab-3' },
    ]

    it('renders CommonTabGroup', () => {
      const wrapper = renderComponent(CommonTabGroup, {
        props: {
          tabs,
        },
      })

      expect(wrapper.getByText('Tab 1')).toBeInTheDocument()
      expect(wrapper.getByText('Tab 2')).toBeInTheDocument()
      expect(wrapper.getByText('Tab 3')).toBeInTheDocument()
    })

    it('does not select any tab by default', () => {
      const wrapper = renderComponent(CommonTabGroup, {
        props: {
          tabs,
        },
      })

      expect(wrapper.queryByRole('tab', { selected: true })).not.toBeInTheDocument()
    })

    it('selects the first tab by default with selectFirstByDefault', async () => {
      const wrapper = renderComponent(CommonTabGroup, {
        props: {
          tabs,
          selectFirstByDefault: true,
        },
      })

      await waitFor(() => {
        expect(wrapper.getByRole('tab', { selected: true })).toHaveTextContent('Tab 1')
      })
    })

    it('selects the default tab with selectFirstByDefault', async () => {
      const wrapper = renderComponent(CommonTabGroup, {
        props: {
          selectFirstByDefault: true,
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

      await waitFor(() => {
        expect(wrapper.getByRole('tab', { selected: true })).toHaveTextContent('Tab 4')
      })
    })

    it('scrolls the active tab into centered view', async () => {
      const scrollIntoViewSpy = vi
        .spyOn(HTMLElement.prototype, 'scrollIntoView')
        .mockImplementation(() => {})

      renderComponent(CommonTabGroup, {
        props: { tabs, modelValue: 'tab-2' },
      })

      await waitFor(() => {
        expect(scrollIntoViewSpy).toHaveBeenCalledWith(
          expect.objectContaining({
            inline: 'center',
          }),
        )
      })

      scrollIntoViewSpy.mockRestore()
    })

    it('switches tab on click', async () => {
      const wrapper = renderComponent(CommonTabGroup, {
        props: {
          tabs: [...tabs],
        },
      })

      await wrapper.events.click(wrapper.getByRole('tab', { name: 'Tab 2' }))

      await waitFor(() => {
        expect(wrapper.getByRole('tab', { selected: true })).toHaveTextContent('Tab 2')
      })
    })

    // normally classes are not tested but in this case as we have no other reliable way
    it('forwards icon-only label support when every tab has an icon', () => {
      const wrapper = renderComponent(CommonTabGroup, {
        props: {
          tabs: [
            { label: 'Tab 1', key: 'tab-1', icon: 'search' },
            { label: 'Tab 2', key: 'tab-2', icon: 'check' },
            { label: 'Tab 3', key: 'tab-3', icon: 'x' },
          ],
        },
      })

      expect(wrapper.getByText('Tab 1')).toHaveClass('sr-only', '@lg:not-sr-only')
      expect(wrapper.getByText('Tab 2')).toHaveClass('sr-only', '@lg:not-sr-only')
      expect(wrapper.getByText('Tab 3')).toHaveClass('sr-only', '@lg:not-sr-only')
    })
  })

  describe('filter mode', () => {
    const filters = [
      { label: 'Admin', key: 'admin' },
      { label: 'Agent', key: 'agent' },
      { label: 'Customer', key: 'customer' },
    ]

    it('renders CommonTabGroup', () => {
      const wrapper = renderComponent(CommonTabGroup, {
        props: {
          tabs: filters,
          label: 'Roles',
          multiple: true,
        },
      })
      // A11y
      expect(wrapper.getByRole('listbox', { name: 'Roles' })).toBeInTheDocument()

      expect(wrapper.getByText('Admin')).toBeInTheDocument()
      expect(wrapper.getByText('Agent')).toBeInTheDocument()
      expect(wrapper.getByText('Customer')).toBeInTheDocument()
    })

    it('selects two filters', async () => {
      const wrapper = renderComponent(CommonTabGroup, {
        props: {
          tabs: filters,
          label: 'Roles',
          multiple: true,
        },
      })

      await wrapper.events.click(wrapper.getByText('Admin'))
      await wrapper.events.click(wrapper.getByText('Agent'))

      await waitFor(() => {
        expect(wrapper.getAllByRole('option', { selected: true })).toHaveLength(2)
      })

      await wrapper.events.click(wrapper.getByText('Admin'))

      await waitFor(() => {
        expect(wrapper.getAllByRole('option', { selected: true })).toHaveLength(1)
      })
    })
  })
})
