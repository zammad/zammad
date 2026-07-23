// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { cloneDeep } from 'lodash-es'
import { computed, ref, type Ref } from 'vue'

import { useTicketArticleUpdatesSubscription } from '#shared/entities/ticket/graphql/subscriptions/ticketArticlesUpdates.api.ts'
import type { KnowledgeBaseAnswerTranslationFragment } from '#shared/graphql/types.ts'
import { QueryHandler, SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'

import { useLinkListQuery } from '#desktop/pages/ticket/graphql/queries/linkList.api.ts'
import { useTicketAiRelatedKnowledgeBaseAnswersQuery } from '#desktop/pages/ticket/graphql/queries/ticketAIRelatedKnowledgeBaseAnswers.api.ts'
import { useTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscription } from '#desktop/pages/ticket/graphql/subscriptions/ticketAIRelatedKnowledgeBaseAnswersUpdates.api.ts'

import type { RelatedAnswer } from '../TicketRelatedKnowledge/types.ts'

export const useKnowledgeBaseLinkList = (
  ticketId: Ref<string>,
  { enabled }: { enabled: Ref<boolean> },
) => {
  // The link target class the ticket's knowledge base answer links are stored under.
  const TARGET_TYPE = 'KnowledgeBase::Answer::Translation'

  const linkListQuery = new QueryHandler(
    useLinkListQuery(
      () => ({
        objectId: ticketId.value,
        targetType: TARGET_TYPE,
      }),
      () => ({ enabled: enabled.value }),
    ),
  )
  const linkListResult = linkListQuery.result()

  const isLoading = linkListQuery.loadingWithoutCachedResult()

  const linkedAnswers = computed(
    () =>
      (linkListResult.value?.linkList ?? []).map(
        (link) => link.item,
      ) as KnowledgeBaseAnswerTranslationFragment[],
  )

  const linkedAnswerIds = computed(() =>
    (linkListResult.value?.linkList ?? []).map((link) => link.item.id),
  )

  return { linkedAnswers, linkedAnswerIds, targetType: TARGET_TYPE, isLoading }
}

export const useKnowledgeBaseAiSuggestedAnswers = (
  ticketId: Ref<string>,
  { enabled }: { enabled: Ref<boolean> },
) => {
  // Synchronous search. Reruns automatically when the ticket changes (reactive variables).
  const queryHandler = new QueryHandler(
    useTicketAiRelatedKnowledgeBaseAnswersQuery(
      () => ({ ticketId: ticketId.value }),
      () => ({ enabled: enabled.value }),
    ),
    { errorShowNotification: false },
  )
  const result = queryHandler.result()
  const loading = queryHandler.loadingWithoutCachedResult()

  // Error from the synchronous query itself (e.g. the vector search failed).
  const searchError = computed(() => queryHandler.operationError().value)

  // Error the embed job could not recover from, delivered via the ping subscription (below). Shown as
  // the error state instead of re-running the search.
  const embedError = ref<string | null>(null)

  const search = computed(() => result.value?.ticketAIRelatedKnowledgeBaseAnswers)
  const rawPending = computed(() => search.value?.pending ?? false)
  const answers = computed<RelatedAnswer[]>(
    () =>
      search.value?.answers?.map((answer) => {
        const updatedAnswer = cloneDeep(answer)
        updatedAnswer.score = Math.round(updatedAnswer.score * 100)

        return updatedAnswer
      }) ?? [],
  )

  const hasError = computed(() => Boolean(embedError.value) || Boolean(searchError.value))
  const errorDetail = computed(() => embedError.value || searchError.value?.message || null)

  // The embedding the search needs is produced asynchronously; we refetch when a ping says it is
  // ready. Count in-flight refetches (ping and article updates can overlap) so the loading state only
  // clears once the last one settles, not the first.
  const refetchingCount = ref(0)
  const pending = computed(() => rawPending.value || refetchingCount.value > 0)

  const refetch = async () => {
    refetchingCount.value += 1
    try {
      await queryHandler.refetch()
    } catch {
      // The failure is surfaced via `searchError` (operationError); swallow the rejection so the
      // fire-and-forget callers (ping/article/retry) never produce an unhandled promise rejection.
    } finally {
      refetchingCount.value -= 1
    }
  }

  // Content-free ping: the embedding the search relies on may have settled. Always subscribed while
  // enabled (not only while pending) so a fast-finishing job can never ping before we are ready.
  const pingSubscription = new SubscriptionHandler(
    useTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscription(
      () => ({ ticketId: ticketId.value }),
      () => ({ enabled: enabled.value }),
    ),
    { errorShowNotification: false },
  )
  pingSubscription.onResult(({ data }) => {
    const update = data?.ticketAIRelatedKnowledgeBaseAnswersUpdates
    // Ignore the initial subscription handshake, which carries no ticketId.
    if (!update?.ticketId) return

    // A failure the embed job could not recover from: show it instead of re-running the search.
    if (update.error) {
      embedError.value = update.error
      return
    }

    embedError.value = null
    refetch()
  })

  // A new (non-system) article changes the ticket content the embedding is built from, so re-run the
  // search when one arrives (also keeps a reactivated same-ticket tab fresh).
  const articleSubscription = new SubscriptionHandler(
    useTicketArticleUpdatesSubscription(
      () => ({ ticketId: ticketId.value }),
      () => ({ enabled: enabled.value }),
    ),
    { errorShowNotification: false },
  )
  articleSubscription.onResult(({ data }) => {
    const addedArticle = data?.ticketArticleUpdates.addArticle
    if (!addedArticle || addedArticle.sender?.name === 'System') return

    embedError.value = null
    refetch()
  })

  const retrySearch = () => {
    embedError.value = null
    refetch()
  }

  return { answers, loading, pending, hasError, errorDetail, retrySearch }
}
