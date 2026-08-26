// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, onScopeDispose, type Ref } from 'vue'

import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'
import { usePagination } from '#shared/composables/usePagination.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import { useKnowledgeBaseSearchQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseSearch.api.ts'
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'

const SEARCH_PAGE_SIZE = 30

export const useKnowledgeBaseSearch = (options: {
  // The already debounced search term — debouncing happens at the input, so
  //   this layer only sees terms worth querying for.
  query: Ref<string>
  // Search scope; absent (or undefined) searches the whole knowledge base.
  categoryId?: Ref<string | undefined>
  locale?: Ref<string | undefined>
}) => {
  const { query, categoryId, locale } = options

  const searchQuery = new QueryHandler(
    useKnowledgeBaseSearchQuery(
      () => ({
        query: query.value,
        categoryId: categoryId?.value,
        locale: locale?.value,
        pageSize: SEARCH_PAGE_SIZE,
      }),
      // A blank term has nothing to search for, so entering the page fires
      //   nothing until the user actually typed something.
      () => ({ enabled: Boolean(query.value.trim()) }),
    ),
    {
      // A category the user may not browse is answered with a 403; the browse
      //   composable redirects to the root, so just swallow the toast here to
      //   avoid a stray notification during that redirect.
      errorCallback: (error) => error.type !== GraphQLErrorTypes.Forbidden,
    },
  )

  const result = searchQuery.result()
  const loading = searchQuery.loadingWithoutCachedResult()

  // Damp the spinner so quick round trips (a new term, a scope refetch) do not
  //   flash a loading state for a few frames.
  const { debouncedLoading } = useDebouncedLoading({ isLoading: loading })

  // No stale-result gating needed: the search view keys this composable's component by
  //   category and locale, so a scope switch drops the instance with its query and
  //   pagination state — reusing the handler would let a `fetchMore` racing the
  //   switch page the new scope with the old cursor.
  const connection = computed(() => normalizeEdges(result.value?.knowledgeBaseSearch))
  const results = computed(() => connection.value.array)
  const totalCount = computed(() => connection.value.totalCount)

  const pagination = usePagination(searchQuery, 'knowledgeBaseSearch', SEARCH_PAGE_SIZE)

  const { contentUpdates } = useKnowledgeBaseStore()

  const { off: stopContentUpdates } = contentUpdates.onResult(({ data }) => {
    if (!query.value.trim()) return

    const affected = data?.knowledgeBaseContentUpdates?.affectedCategoryIds ?? []

    // Unlike the answer list, a search cannot filter on the directly changed
    //   category: a hit anywhere in the searched subtree is relevant. So refetch
    //   on any change within the scope — an unscoped (root) search, a
    //   knowledge-base-wide change (empty list), or the scope appearing anywhere
    //   in the payload (the changed record's category or one of its ancestors).
    const scope = categoryId?.value
    if (scope && affected.length > 0 && !affected.includes(scope)) return

    // Pin the refetch to the current args explicitly, like the sibling composables do, rather
    //   than relying on what the reactive query function last pushed into the query.
    searchQuery.refetch({
      query: query.value,
      categoryId: scope,
      locale: locale?.value,
      pageSize: SEARCH_PAGE_SIZE,
    })
  })

  onScopeDispose(stopContentUpdates)

  return {
    results,
    totalCount,
    pagination,
    loading,
    debouncedLoading,
  }
}
