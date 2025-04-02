// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'

import { useSessionStore } from '#shared/stores/session.ts'

const RECENTLY_SEARCHES_MAX_LENGTH = 10
const ADD_RECENT_SEARCH_DEBOUNCE_TIME = 1000

export const useRecentSearches = (maxLength = RECENTLY_SEARCHES_MAX_LENGTH) => {
  const { userId } = useSessionStore()

  const recentSearches = useLocalStorage<string[]>(
    `${userId}-recentSearches`,
    [],
  )

  const addSearch = (search?: string) => {
    if (!search) return

    // Remove the search term if it already exists to avoid duplicates
    recentSearches.value = recentSearches.value.filter(
      (item) => item !== search,
    )

    // Add the new search term
    recentSearches.value.push(search)

    // Remove the oldest search if we exceed the maximum length
    if (recentSearches.value.length > maxLength) {
      recentSearches.value.shift()
    }
  }

  const removeSearch = (search: string) => {
    recentSearches.value = recentSearches.value.filter(
      (item) => item !== search,
    )
  }

  const clearSearches = () => {
    recentSearches.value = []
  }

  return {
    ADD_RECENT_SEARCH_DEBOUNCE_TIME,
    recentSearches,
    addSearch,
    removeSearch,
    clearSearches,
  }
}
