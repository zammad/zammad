// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { createPinia, setActivePinia } from 'pinia'

import { waitForNextTick } from '#tests/support/utils.ts'

import { useRecentSearches } from '../useRecentSearches.ts'

setActivePinia(createPinia())

describe('useRecentSearches', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  const { recentSearches, addSearch, removeSearch, clearSearches } =
    useRecentSearches()

  test('prevents duplicate search terms', () => {
    addSearch('test search')
    addSearch('test search')
    expect(recentSearches.value).toEqual(['test search'])
  })

  test('maintains maximum length and removes oldest items', () => {
    for (let i = 1; i <= 11; i += 1) {
      addSearch(`search ${i}`)
    }

    expect(recentSearches.value).toEqual([
      'search 2',
      'search 3',
      'search 4',
      'search 5',
      'search 6',
      'search 7',
      'search 8',
      'search 9',
      'search 10',
      'search 11',
    ])
  })

  test('removeSearch removes a specific item', () => {
    clearSearches()

    addSearch('test 1')
    addSearch('test 2')

    expect(recentSearches.value).toEqual(['test 1', 'test 2'])

    removeSearch('test 1')

    expect(recentSearches.value).toEqual(['test 2'])
  })

  test('clearSearches removes all items', () => {
    addSearch('test 1')
    addSearch('test 2')

    clearSearches()

    expect(recentSearches.value).toEqual([])
  })

  test('persists searches in localStorage', async () => {
    addSearch('test storage')

    await waitForNextTick()

    const { recentSearches: newInstance } = useRecentSearches()
    expect(newInstance.value).toEqual(['test storage'])
  })
})
