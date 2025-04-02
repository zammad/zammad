// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'

import SearchControls from '../SearchControls.vue'

mockRouterHooks()

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
    expect(
      wrapper.getByRole('tab', { name: 'Organization 11' }),
    ).toBeInTheDocument()
    expect(wrapper.getByRole('tab', { name: 'Ticket 22' })).toBeInTheDocument()
    expect(wrapper.getByRole('tab', { name: 'User 33' })).toBeInTheDocument()
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
})
