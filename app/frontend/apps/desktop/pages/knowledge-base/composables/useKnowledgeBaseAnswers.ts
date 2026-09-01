// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, onScopeDispose, type Ref } from 'vue'

import { usePagination } from '#shared/composables/usePagination.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import { useKnowledgeBaseAnswersQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.api.ts'
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'

const ANSWERS_PAGE_SIZE = 30

export const useKnowledgeBaseAnswers = (options: {
  categoryId: Ref<string | undefined>
  locale?: Ref<string | undefined>
}) => {
  const { categoryId, locale } = options

  const answersQuery = new QueryHandler(
    useKnowledgeBaseAnswersQuery(
      () => ({
        categoryId: categoryId.value as string,
        locale: locale?.value,
        pageSize: ANSWERS_PAGE_SIZE,
      }),
      // Answers exist only below a specific category; the knowledge base root
      //   has none, so the query stays disabled until a category is opened.
      () => ({ enabled: Boolean(categoryId.value) }),
    ),
    {
      // A category the user may not browse is answered with a 403; the browse
      //   composable redirects to the root, so just swallow the toast here to
      //   avoid a stray notification during that redirect.
      errorCallback: (error) => error.type !== GraphQLErrorTypes.Forbidden,
    },
  )

  const result = answersQuery.result()
  const loading = answersQuery.loadingWithoutCachedResult()

  // No stale-result gating needed: the browse view keys this composable's component by
  //   category and locale, so an instance only ever sees the arguments it was created
  //   with — a different list is a different instance.
  const connection = computed(() => normalizeEdges(result.value?.knowledgeBaseAnswers))
  const answers = computed(() => connection.value.array)
  const totalAnswerCount = computed(() => connection.value.totalCount)

  const pagination = usePagination(answersQuery, 'knowledgeBaseAnswers', ANSWERS_PAGE_SIZE)

  // How much to ask for when the whole listing has to be re-read. Refetching a single page would
  //   collapse an already scrolled list back to its first one — throwing the reader to the top of
  //   the category — so a refetch covers every page loaded so far and replaces the loaded window
  //   one for one instead.
  const loadedPageSize = () =>
    Math.max(Math.ceil(answers.value.length / ANSWERS_PAGE_SIZE), 1) * ANSWERS_PAGE_SIZE

  // Refetch the answers only when the change happened directly in the open
  //   category (the payload lists the changed record's category first, then its
  //   ancestors) or on a knowledge-base-wide change — a change in a descendant
  //   category does not alter this category's direct answers.
  const { contentUpdates } = useKnowledgeBaseStore()

  const { off: stopContentUpdates } = contentUpdates.onResult(({ data }) => {
    if (!categoryId.value) return

    const affected = data?.knowledgeBaseContentUpdates?.affectedCategoryIds ?? []

    // Refetch on a knowledge-base-wide change (empty), or when the change
    //   happened directly in this category — the payload lists the changed
    //   record's category first, then its ancestors, so a change in a
    //   descendant (this category only as an ancestor) does not match.
    if (affected.length === 0 || affected[0] === categoryId.value) {
      // Pin the refetch to the current args explicitly, like the sibling composables do, rather
      //   than relying on what the reactive query function last pushed into the query.
      answersQuery.refetch({
        categoryId: categoryId.value,
        locale: locale?.value,
        pageSize: loadedPageSize(),
      })
    }
  })

  onScopeDispose(stopContentUpdates)

  return {
    answers,
    totalAnswerCount,
    pagination,
    loading,
  }
}
