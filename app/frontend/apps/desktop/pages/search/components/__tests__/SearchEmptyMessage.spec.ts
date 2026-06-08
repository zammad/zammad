// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import SearchEmptyMessage from '#desktop/pages/search/components/SearchEmptyMessage.vue'

const renderSearchEmptyMessage = (hasActiveSearch = false, results = []) =>
  renderComponent(SearchEmptyMessage, {
    props: {
      hasActiveSearch,
      results,
    },
  })

describe('SearchEmptyMessage', () => {
  it('displays message if user has not searched yet', async () => {
    const wrapper = renderSearchEmptyMessage()

    expect(wrapper.getByIconName('search')).toBeInTheDocument()
    expect(
      wrapper.getByText('Start typing or apply filters to get the search results.'),
    ).toBeInTheDocument()

    await wrapper.rerender({ hasActiveSearch: false, results: [] })

    expect(
      wrapper.getByText('Start typing or apply filters to get the search results.'),
    ).toBeInTheDocument()
  })

  it('displays no results message if user has searched', () => {
    const wrapper = renderSearchEmptyMessage(true, [])

    expect(wrapper.getByIconName('search')).toBeInTheDocument()
    expect(wrapper.queryByText('No results found.')).not.toBeInTheDocument()

    expect(wrapper.getByText('No search results for this query.')).toBeInTheDocument()
  })
})
