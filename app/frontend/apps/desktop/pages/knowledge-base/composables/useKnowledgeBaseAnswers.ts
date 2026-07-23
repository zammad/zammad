// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'

import { usePagination } from '#shared/composables/usePagination.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import { useKnowledgeBaseAnswersQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.api.ts'

import { useKnowledgeBaseStore } from '../../../entities/knowledge-base/stores/knowledgeBase.ts'

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

  // A disabled query keeps its last result, so without gating on `categoryId`
  //   the previously opened category's answers would linger at the knowledge
  const connection = computed(() =>
    normalizeEdges(categoryId.value ? result.value?.knowledgeBaseAnswers : undefined),
  )
  const answers = computed(() => connection.value.array)
  const totalAnswerCount = computed(() => connection.value.totalCount)

  const pagination = usePagination(answersQuery, 'knowledgeBaseAnswers', ANSWERS_PAGE_SIZE)

  // Refetch the answers only when the change happened directly in the open
  //   category (the payload lists the changed record's category first, then its
  //   ancestors) or on a knowledge-base-wide change — a change in a descendant
  //   category does not alter this category's direct answers.
  const { contentUpdates } = useKnowledgeBaseStore()

  contentUpdates.onResult(({ data }) => {
    if (!categoryId.value) return

    const affected = data?.knowledgeBaseContentUpdates?.affectedCategoryIds ?? []

    // Refetch on a knowledge-base-wide change (empty), or when the change
    //   happened directly in this category — the payload lists the changed
    //   record's category first, then its ancestors, so a change in a
    //   descendant (this category only as an ancestor) does not match.
    if (affected.length === 0 || affected[0] === categoryId.value) answersQuery.refetch()
  })

  return {
    answers,
    totalAnswerCount,
    pagination,
    loading,
  }
}
