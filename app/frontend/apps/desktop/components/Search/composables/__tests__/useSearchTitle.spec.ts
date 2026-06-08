// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { useSearchTitle } from '#desktop/components/Search/composables/useSearchTitle.ts'

describe('useSearchTitle', () => {
  it('returns the fallback title when search term and filter count are empty', () => {
    const { searchTitle } = useSearchTitle(ref(''), ref(0))

    expect(searchTitle.value).toBe('Extended search')
  })

  it('returns only the search term when no filters are applied', () => {
    const { searchTitle } = useSearchTitle(ref('foo'), ref(0))

    expect(searchTitle.value).toBe('foo')
  })

  it('returns only the filter count when search term is empty', () => {
    const { searchTitle } = useSearchTitle(ref(''), ref(2))

    expect(searchTitle.value).toBe('2 filter(s)')
  })

  it('combines search term and filter count', () => {
    const { searchTitle } = useSearchTitle(ref('foo'), ref(2))

    expect(searchTitle.value).toBe('foo + 2 filter(s)')
  })
})
