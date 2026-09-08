// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, onScopeDispose, ref, watch, type Ref } from 'vue'

import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'
import { usePagination } from '#shared/composables/usePagination.ts'
import { EnumKnowledgeBaseSearchEntity } from '#shared/graphql/types.ts'
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
  // The kind of content the result list shows. Only which of the two searches below is rendered:
  //   both of them run either way.
  entity: Ref<EnumKnowledgeBaseSearchEntity>
  // Search scope; absent (or undefined) searches the whole knowledge base.
  categoryId?: Ref<string | undefined>
  locale?: Ref<string | undefined>
}) => {
  const { query, entity, categoryId, locale } = options

  // A blank term has nothing to search for, so entering the page fires
  //   nothing until the user actually typed something.
  const searching = () => ({ enabled: Boolean(query.value.trim()) })

  // One search per kind of content, because one search returns one kind. Both always run: that is
  //   what gives each tab a real count of its own, and it means switching to the other kind has
  //   its results already rather than starting a round trip.
  //
  // Each handler is pinned to its kind, so a tab switch changes no variables of either — no
  //   refetch, and no count blinking while the other one answers.
  const searchFor = (searchEntity: EnumKnowledgeBaseSearchEntity) =>
    new QueryHandler(
      useKnowledgeBaseSearchQuery(
        () => ({
          query: query.value,
          entity: searchEntity,
          categoryId: categoryId?.value,
          locale: locale?.value,
          pageSize: SEARCH_PAGE_SIZE,
        }),
        searching,
      ),
      {
        // A category the user may not browse is answered with a 403; the browse
        //   composable redirects to the root, so just swallow the toast here to
        //   avoid a stray notification during that redirect.
        errorCallback: (error) => error.type !== GraphQLErrorTypes.Forbidden,
      },
    )

  const answerSearch = searchFor(EnumKnowledgeBaseSearchEntity.Answer)
  const categorySearch = searchFor(EnumKnowledgeBaseSearchEntity.Category)

  const answerResult = answerSearch.result()
  const categoryResult = categorySearch.result()

  const answerLoading = answerSearch.loadingWithoutCachedResult()
  const categoryLoading = categorySearch.loadingWithoutCachedResult()

  const answerPagination = usePagination(answerSearch, 'knowledgeBaseSearch', SEARCH_PAGE_SIZE)
  const categoryPagination = usePagination(categorySearch, 'knowledgeBaseSearch', SEARCH_PAGE_SIZE)

  const showsAnswers = computed(() => entity.value === EnumKnowledgeBaseSearchEntity.Answer)

  // Which search a response belongs to. The two queries answer independently, and vue-apollo keeps
  //   the last result of each until a new one arrives — so once a new term is committed, a kind
  //   that has not answered yet is still holding the *previous* term's hits and total. Rendering
  //   those would put one tab a search behind the other, and switching tabs would show hits of a
  //   term the field no longer contains, with nothing to say so.
  const revision = computed(() =>
    JSON.stringify([query.value.trim(), categoryId?.value ?? null, locale?.value ?? null]),
  )

  const answeredRevision = {
    [EnumKnowledgeBaseSearchEntity.Answer]: ref<string>(),
    [EnumKnowledgeBaseSearchEntity.Category]: ref<string>(),
  }

  // A result only ever *changes* for the variables the query currently has, so the revision at
  //   that moment is the one it belongs to. `fetchMore` appends within the same revision.
  watch(answerResult, () => {
    answeredRevision[EnumKnowledgeBaseSearchEntity.Answer].value = revision.value
  })

  watch(categoryResult, () => {
    answeredRevision[EnumKnowledgeBaseSearchEntity.Category].value = revision.value
  })

  const answeredCurrent = (searchEntity: EnumKnowledgeBaseSearchEntity) =>
    computed(() => answeredRevision[searchEntity].value === revision.value)

  const answersCurrent = answeredCurrent(EnumKnowledgeBaseSearchEntity.Answer)
  const categoriesCurrent = answeredCurrent(EnumKnowledgeBaseSearchEntity.Category)

  // Each kind's own total, but only once that kind has answered *this* search. `undefined` until
  //   then, which is what a tab badge renders as `-` — rather than a number belonging to the term
  //   before it.
  const answerCount = computed(() =>
    answersCurrent.value ? answerResult.value?.knowledgeBaseSearch.totalCount : undefined,
  )

  const categoryCount = computed(() =>
    categoriesCurrent.value ? categoryResult.value?.knowledgeBaseSearch.totalCount : undefined,
  )

  // Everything below is the search being *rendered*; the other one is only counted.
  const shownAnswered = computed(() =>
    showsAnswers.value ? answersCurrent.value : categoriesCurrent.value,
  )

  const shownSearch = computed(() =>
    showsAnswers.value
      ? answerResult.value?.knowledgeBaseSearch
      : categoryResult.value?.knowledgeBaseSearch,
  )

  const connection = computed(() =>
    normalizeEdges(shownAnswered.value ? shownSearch.value : undefined),
  )

  const results = computed(() => connection.value.array)
  const totalCount = computed(() => connection.value.totalCount)

  // A kind that has not answered this search yet counts as loading, so the list shows its skeleton
  //   instead of the previous term's hits — including when a tab is switched to before its own
  //   search has come back.
  const loading = computed(() => {
    if (!query.value.trim()) return false

    if (!shownAnswered.value) return true

    return showsAnswers.value ? answerLoading.value : categoryLoading.value
  })

  // Damp the spinner so quick round trips (a new term, a scope refetch) do not
  //   flash a loading state for a few frames.
  const { debouncedLoading } = useDebouncedLoading({ isLoading: loading })

  // Paging applies to the list on screen. A computed rather than one object, because which of the
  //   two it is follows the selected tab.
  const pagination = computed(() => (showsAnswers.value ? answerPagination : categoryPagination))

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
    //   than relying on what the reactive query function last pushed into the query. Both
    //   searches, each with its own kind: the tab that is not shown would keep a stale count.
    const args = {
      query: query.value,
      categoryId: scope,
      locale: locale?.value,
      pageSize: SEARCH_PAGE_SIZE,
    }

    answerSearch.refetch({ ...args, entity: EnumKnowledgeBaseSearchEntity.Answer })
    categorySearch.refetch({ ...args, entity: EnumKnowledgeBaseSearchEntity.Category })
  })

  onScopeDispose(stopContentUpdates)

  return {
    results,
    totalCount,
    answerCount,
    categoryCount,
    pagination,
    loading,
    debouncedLoading,
  }
}
