// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useTimeoutFn } from '@vueuse/core'
import { useRouteQuery } from '@vueuse/router'
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'

// search_field_widget.coffee:82
export const SEARCH_DEBOUNCE_TIME = 500

// The browsed search term. The URL owns it — as it owns the browsed locale
//   (knowledgeBase.ts) — so a deep link, a back/forward and a shared link all restore the
//   same page, and the result list can read the term straight off the route instead of
//   being handed it. The field shows the URL's term, except while typing runs ahead of it.
//
// `debounceTime` is injectable so specs can drive the commit without fake timers.
export const useKnowledgeBaseSearchTerm = (debounceTime = SEARCH_DEBOUNCE_TIME) => {
  const route = useRoute()

  const searchQuery = useRouteQuery<string | string[] | null, string>('query', '', {
    transform: (value) => ((Array.isArray(value) ? value.at(-1) : value) ?? '').trim(),
  })

  const typedTerm = ref<string>()

  const commit = () => {
    searchQuery.value = typedTerm.value?.trim() ?? ''
  }

  const { start: commitLater, stop: cancelCommit } = useTimeoutFn(commit, debounceTime, {
    immediate: false,
  })

  const searchTerm = computed({
    get: () => typedTerm.value ?? searchQuery.value,
    set: (term) => {
      typedTerm.value = term
      cancelCommit()

      // Trailing whitespace is not a different search, so it does not start one.
      const trimmed = term.trim()
      if (trimmed === searchQuery.value) return

      // Emptying the field is not a search either.
      if (trimmed) commitLater()
      else commit()
    },
  })

  // Picking a suggested search is a deliberate choice, not typing, so it searches at once
  //   (search_field_widget.coffee:146) instead of waiting out the debounce.
  const searchNow = (term: string) => {
    cancelCommit()
    typedTerm.value = term
    commit()
  }

  // Any navigation ends typing: our own commit landing, a back/forward, a link carrying
  //   `?query=`, or a move to another category or locale — which is another scope
  //   ("Search within %s"), and so another search.
  watch(
    () => route.fullPath,
    () => {
      cancelCommit()
      typedTerm.value = undefined
    },
  )

  return { searchTerm, searchQuery, searchNow }
}
