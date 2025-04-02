// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import SearchEmptyMessage from '#desktop/pages/search/components/SearchEmptyMessage.vue'

const renderSearchEmptyMessage = (searchTerm = '', results = []) =>
  renderComponent(SearchEmptyMessage, {
    props: {
      searchTerm,
      results,
    },
  })

describe('SearchEmptyMessage', () => {
  it('displays message if user has not searched yet', async () => {
    const wrapper = renderSearchEmptyMessage()
    expect(wrapper.getByIconName('search')).toBeInTheDocument()
    expect(
      wrapper.getByText('Start typing to get the search results.'),
    ).toBeInTheDocument()

    await wrapper.rerender({ searchTerm: '     ', result: [] })

    expect(
      wrapper.getByText('Start typing to get the search results.'),
    ).toBeInTheDocument()
  })

  it('displays no results message if user has searched', () => {
    const wrapper = renderSearchEmptyMessage('test', [])

    expect(wrapper.getByIconName('search')).toBeInTheDocument()
    expect(wrapper.queryByText('No results found.')).not.toBeInTheDocument()

    expect(
      wrapper.getByText('No search results for this query.'),
    ).toBeInTheDocument()
  })

  it('emits event when user clicks on clear search', async () => {
    const wrapper = renderSearchEmptyMessage('test', [])

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Clear search' }),
    )

    expect(wrapper.emitted('clear-search-input')).toHaveLength(1)
  })
})
