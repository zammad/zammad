// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'

import SearchControls from '../SearchControls.vue'

mockRouterHooks()

const mockWaitForConfirmation = vi.hoisted(() => vi.fn())

vi.mock('#shared/composables/useConfirmation.ts', () => ({
  useConfirmation: () => ({
    waitForConfirmation: mockWaitForConfirmation,
  }),
}))

describe('SearchControls', () => {
  it('renders the search input and tabs', async () => {
    const wrapper = renderComponent(SearchControls, {
      props: {
        searchTabs: [
          { label: 'Organization', key: 'Organization', count: 11 },
          { label: 'Ticket', key: 'Ticket', count: 22 },
          { label: 'User', key: 'User', count: 33 },
        ],
      },
    })

    expect(
      wrapper.getByRole('searchbox', {
        name: 'Search…',
      }),
    ).toBeInTheDocument()

    expect(wrapper.getByRole('tablist')).toBeInTheDocument()
    expect(wrapper.getAllByRole('tab')).toHaveLength(3)
    expect(wrapper.getByRole('tab', { name: 'Organization' })).toHaveTextContent('11')
    expect(wrapper.getByRole('tab', { name: 'Ticket' })).toHaveTextContent('22')
    expect(wrapper.getByRole('tab', { name: 'User' })).toHaveTextContent('33')
  })

  it('updates the search term when input changes', async () => {
    vi.useFakeTimers()
    const search = ref('old search term')
    const selectedEntity = ref('Ticket')

    const wrapper = renderComponent(SearchControls, {
      props: {
        searchTabs: [
          { label: 'Organization', key: 'Organization', count: 1 },
          { label: 'Ticket', key: 'Ticket', count: 22 },
          { label: 'User', key: 'User', count: 23 },
        ],
      },
      vModel: {
        search,
        selectedEntity,
      },
    })

    const input = wrapper.getByRole('searchbox', { name: 'Search…' })

    await wrapper.events.clear(input)
    await wrapper.events.type(input, 'new search term')

    await vi.advanceTimersToNextTimerAsync()

    expect(search.value).toBe('new search term')

    vi.useRealTimers()
  })

  it('changes the active tab when a tab is clicked', async () => {
    const search = ref('old search term')
    const selectedEntity = ref('Ticket')

    const wrapper = renderComponent(SearchControls, {
      props: {
        searchTabs: [
          { label: 'Organization', key: 'Organization', count: 1 },
          { label: 'Ticket', key: 'Ticket', count: 22 },
          { label: 'User', key: 'User', count: 23 },
        ],
      },
      vModel: {
        search,
        selectedEntity,
      },
    })

    const tabs = wrapper.getAllByRole('tab')

    await wrapper.events.click(tabs[0])

    expect(tabs[0]).toHaveAttribute('aria-selected', 'true')

    expect(selectedEntity.value).toBe('Organization')
  })

  describe('Advanced filters panel', () => {
    it('toggles the advanced filters panel when the button is clicked', async () => {
      const wrapper = renderComponent(SearchControls, {
        props: {
          searchTabs: [
            { label: 'Organization', key: 'Organization', count: 11 },
            { label: 'Ticket', key: 'Ticket', count: 22 },
            { label: 'User', key: 'User', count: 33 },
          ],
        },
      })

      const button = wrapper.getByRole('button', { name: 'Advanced filters' })

      expect(button).toHaveAttribute('aria-expanded', 'false')

      await wrapper.events.click(button)

      expect(button).toHaveAttribute('aria-expanded', 'true')
      expect(wrapper.getByLabelText('Advanced filters')).toBeInTheDocument()
    })

    it('shows badge with selected filter count', async () => {
      const wrapper = renderComponent(SearchControls, {
        props: {
          searchTabs: [
            { label: 'Organization', key: 'Organization', count: 11 },
            { label: 'Ticket', key: 'Ticket', count: 22 },
            { label: 'User', key: 'User', count: 33 },
          ],
          filterCount: 3,
        },
      })

      const badge = wrapper.getByRole('button', { name: '3 filter(s)' })
      expect(badge).toBeInTheDocument()
    })

    it('shows advanced filters expanded on initial load when filters are present', async () => {
      const wrapper = renderComponent(SearchControls, {
        props: {
          searchTabs: [
            { label: 'Organization', key: 'Organization', count: 11 },
            { label: 'Ticket', key: 'Ticket', count: 22 },
            { label: 'User', key: 'User', count: 33 },
          ],
          filterCount: 3,
        },
      })

      const badge = wrapper.getByRole('button', { name: '3 filter(s)' })

      const button = wrapper.getByRole('button', { name: 'Advanced filters' })
      // Initially on mounted we expect the panel to be open if filters are present
      expect(button).toHaveAttribute('aria-expanded', 'true')

      await wrapper.events.click(badge)

      expect(button).toHaveAttribute('aria-expanded', 'true')
    })

    it('does not show badge when filterCount is 0', () => {
      const wrapper = renderComponent(SearchControls, {
        props: {
          searchTabs: [
            { label: 'Organization', key: 'Organization', count: 11 },
            { label: 'Ticket', key: 'Ticket', count: 22 },
            { label: 'User', key: 'User', count: 33 },
          ],
          filterCount: 0,
        },
      })

      expect(wrapper.queryByRole('button', { name: /filter\(s\)/ })).not.toBeInTheDocument()
    })

    it('opens the filter panel when the badge button is clicked', async () => {
      const wrapper = renderComponent(SearchControls, {
        props: {
          searchTabs: [
            { label: 'Organization', key: 'Organization', count: 11 },
            { label: 'Ticket', key: 'Ticket', count: 22 },
            { label: 'User', key: 'User', count: 33 },
          ],
          filterCount: 2,
        },
      })

      const advancedFiltersButton = wrapper.getByRole('button', { name: 'Advanced filters' })
      // Panel is already open because filterCount > 0; close it first
      await wrapper.events.click(advancedFiltersButton)
      expect(advancedFiltersButton).toHaveAttribute('aria-expanded', 'false')

      const badgeButton = wrapper.getByRole('button', { name: '2 filter(s)' })
      await wrapper.events.click(badgeButton)

      expect(advancedFiltersButton).toHaveAttribute('aria-expanded', 'true')
    })

    it('emits clear-filters and closes panel when badge clear filters is confirmed', async () => {
      mockWaitForConfirmation.mockResolvedValue(true)

      const wrapper = renderComponent(SearchControls, {
        props: {
          searchTabs: [
            { label: 'Organization', key: 'Organization', count: 11 },
            { label: 'Ticket', key: 'Ticket', count: 22 },
            { label: 'User', key: 'User', count: 33 },
          ],
          filterCount: 2,
        },
      })

      const clearButton = wrapper.getByRole('button', { name: 'Clear all filters' })
      await wrapper.events.click(clearButton)

      await vi.waitFor(() => expect(wrapper.emitted('clear-filters')).toHaveLength(1))
    })

    it('does not emit clear-filters when badge clear filters confirmation is cancelled', async () => {
      mockWaitForConfirmation.mockResolvedValue(false)

      const wrapper = renderComponent(SearchControls, {
        props: {
          searchTabs: [
            { label: 'Organization', key: 'Organization', count: 11 },
            { label: 'Ticket', key: 'Ticket', count: 22 },
            { label: 'User', key: 'User', count: 33 },
          ],
          filterCount: 2,
        },
      })

      const badgeClearButton = wrapper.getByRole('button', { name: 'Clear all filters' })
      await wrapper.events.click(badgeClearButton)

      await vi.waitFor(() => {
        expect(mockWaitForConfirmation).toHaveBeenCalled()
      })

      expect(wrapper.emitted('clear-filters')).toBeUndefined()
    })

    it('has correct aria attributes linking button and section', () => {
      const wrapper = renderComponent(SearchControls, {
        props: {
          searchTabs: [
            { label: 'Organization', key: 'Organization', count: 11 },
            { label: 'Ticket', key: 'Ticket', count: 22 },
            { label: 'User', key: 'User', count: 33 },
          ],
        },
      })

      const button = wrapper.getByRole('button', { name: 'Advanced filters' })
      const sectionId = button.getAttribute('aria-controls')

      expect(sectionId).toBeTruthy()
      expect(wrapper.baseElement.querySelector(`#${sectionId}`)).toBeInTheDocument()
    })
  })
})
