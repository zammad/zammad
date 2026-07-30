// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { cloneDeep } from 'lodash-es'
import { computed, ref, toValue, type MaybeRef, type Ref } from 'vue'

import { useTicketArticleUpdatesSubscription } from '#shared/entities/ticket/graphql/subscriptions/ticketArticlesUpdates.api.ts'
import { QueryHandler, SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'

import { useTicketAiRelatedKnowledgeBaseAnswersQuery } from '#desktop/pages/ticket/graphql/queries/ticketAIRelatedKnowledgeBaseAnswers.api.ts'
import { useTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscription } from '#desktop/pages/ticket/graphql/subscriptions/ticketAIRelatedKnowledgeBaseAnswersUpdates.api.ts'

import type { RelatedAnswer } from '../TicketRelatedKnowledge/types.ts'
import type { WatchQueryFetchPolicy } from '@apollo/client'

export const useKnowledgeBaseAiSuggestedAnswers = (
  ticketId: Ref<string>,
  {
    queryEnabled = true,
    subscriptionEnabled = true,
    fetchPolicy = 'cache-and-network',
  }: {
    queryEnabled?: MaybeRef<boolean>
    subscriptionEnabled?: MaybeRef<boolean>
    fetchPolicy?: MaybeRef<WatchQueryFetchPolicy>
  } = {},
) => {
  const isQueryEnabled = computed(() => toValue(queryEnabled))
  const isSubscriptionEnabled = computed(() => toValue(subscriptionEnabled))
  const reactiveFetchPolicy = computed(() => toValue(fetchPolicy))

  // Synchronous search. Reruns automatically when the ticket changes (reactive variables).
  const queryHandler = new QueryHandler(
    useTicketAiRelatedKnowledgeBaseAnswersQuery(
      () => ({ ticketId: ticketId.value }),
      () => ({ enabled: isQueryEnabled.value, fetchPolicy: reactiveFetchPolicy.value }),
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
      () => ({ enabled: isSubscriptionEnabled.value }),
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
      () => ({ enabled: isSubscriptionEnabled.value }),
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
