// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useTimeoutFn } from '@vueuse/core'
import { useRouteQuery } from '@vueuse/router'
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'

import { EnumKnowledgeBaseSearchEntity } from '#shared/graphql/types.ts'

// search_field_widget.coffee:82
export const SEARCH_DEBOUNCE_TIME = 500

const SEARCH_ENTITIES: string[] = Object.values(EnumKnowledgeBaseSearchEntity)

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

  // The kind of content the result list shows, under the same parameter name the global detail
  //   search keeps its entity under (pages/search/views/Search.vue). The URL owns it as it owns
  //   the term, so a shared link and a back/forward restore the tab that was open. A value the
  //   schema does not know reads as the default rather than failing the query.
  const searchEntity = useRouteQuery<string | string[] | null, EnumKnowledgeBaseSearchEntity>(
    'entity',
    EnumKnowledgeBaseSearchEntity.Answer,
    {
      transform: (value) => {
        const entity = (Array.isArray(value) ? value.at(-1) : value) ?? ''

        return SEARCH_ENTITIES.includes(entity)
          ? (entity as EnumKnowledgeBaseSearchEntity)
          : EnumKnowledgeBaseSearchEntity.Answer
      },
    },
  )

  const typedTerm = ref<string>()

  const commit = () => {
    const term = typedTerm.value?.trim() ?? ''

    searchQuery.value = term

    // Clearing the term ends the search, so the kind it was showing goes with it: the next search
    //   starts on the answers again, and no stale `?entity=` is left on a plain browse URL that is
    //   then shared or bookmarked. Here rather than in a handler of its own, because the field's
    //   clear icon and the empty state's button both arrive through this one place.
    if (!term) searchEntity.value = EnumKnowledgeBaseSearchEntity.Answer
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

  // A foreign navigation ends typing: a back/forward, a link carrying `?query=`, or a move to
  //   another category or locale — which is another scope ("Search within %s"), and so another
  //   search. Our own commit landing is not one: the URL holds the trimmed term, but the field
  //   keeps what is being typed, or a pause after `printer ` would drop the space and the next
  //   word would run on as `printerjam`.
  //
  // Watched as the path and the term rather than the whole `fullPath`, because switching the tab
  //   writes `?entity=` — a change to this very page that must not abort the pending commit and
  //   discard what is half typed. The browsed category and locale are both in the path.
  watch([() => route.path, () => searchQuery.value], () => {
    cancelCommit()

    if (typedTerm.value?.trim() !== searchQuery.value) typedTerm.value = undefined
  })

  return { searchTerm, searchQuery, searchEntity, searchNow }
}
