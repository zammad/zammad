// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useDebounceFn } from '@vueuse/core'
import { ref, watch } from 'vue'

import type { Ref } from 'vue'

// Mirrors FieldAutoComplete's `isUserTyping` guard: the typing + query-debounce
// window is treated as "loading" so the suggestion popup never shows (or
// announces) "No results found" before the results for the new query arrive —
// e.g. when the previous query was also empty. Cleared instantly once the query
// is emptied, otherwise shortly after the user stops typing.
export const useSuggestionTyping = (query: Ref<string>) => {
  const isTyping = ref(false)

  const stopTyping = useDebounceFn(() => {
    isTyping.value = false
  }, 300)

  watch(query, (value) => {
    if (value === '') {
      isTyping.value = false
      return
    }
    isTyping.value = true
    stopTyping()
  })

  return isTyping
}
