// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { cloneDeep } from 'lodash-es'
import { computed, ref, toValue, type MaybeRef, type MaybeRefOrGetter, type Ref } from 'vue'

import { QueryHandler, SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'

import { useTicketArticleCountChange } from '#desktop/pages/ticket/composables/useTicketArticleCountChange.ts'
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
    includeDraftsAndArchived = false,
    includeLinkedAnswers = false,
    articleCount,
  }: {
    queryEnabled?: MaybeRef<boolean>
    subscriptionEnabled?: MaybeRef<boolean>
    fetchPolicy?: MaybeRef<WatchQueryFetchPolicy>
    // Whether drafts and archived answers count as a suggestion, too. Only of interest when asking
    // whether an answer already covers the ticket's topic, not when looking for one to work with.
    includeDraftsAndArchived?: MaybeRef<boolean>
    // Whether answers already linked to the ticket are part of the result. The sidebar lists them
    // on its own, so it leaves them out; asking about coverage they count most of all.
    includeLinkedAnswers?: MaybeRef<boolean>
    // The ticket's article count, handed in by the caller from the ticket it holds: a change to it
    // means the conversation moved on and the search has to run again.
    articleCount?: MaybeRefOrGetter<Maybe<number> | undefined>
  } = {},
) => {
  const isQueryEnabled = computed(() => toValue(queryEnabled))
  const isSubscriptionEnabled = computed(() => toValue(subscriptionEnabled))
  const reactiveFetchPolicy = computed(() => toValue(fetchPolicy))

  // Synchronous search. Reruns automatically when the ticket changes (reactive variables).
  const queryHandler = new QueryHandler(
    useTicketAiRelatedKnowledgeBaseAnswersQuery(
      () => ({
        ticketId: ticketId.value,
        includeDraftsAndArchived: toValue(includeDraftsAndArchived),
        includeLinkedAnswers: toValue(includeLinkedAnswers),
      }),
      () => ({ enabled: isQueryEnabled.value, fetchPolicy: reactiveFetchPolicy.value }),
    ),
    { errorShowNotification: false },
  )
  const result = queryHandler.result()
  const loading = queryHandler.loadingWithoutCachedResult()

  // Error from the synchronous query itself (e.g. the vector search failed). Read from the handler
  // rather than notified, because the flyout and the sidebar render it in place, with a retry.
  const searchError = queryHandler.operationError()

  // Error the embed job could not recover from, delivered via the ping subscription (below). Shown as
  // the error state instead of re-running the search.
  const embedError = ref<string | null>(null)

  const search = computed(() => result.value?.ticketAIRelatedKnowledgeBaseAnswers)
  const rawPending = computed(() => search.value?.pending ?? false)
  const answers = computed<RelatedAnswer[]>(
    () =>
      search.value?.answers?.map((answer) => {
        const updatedAnswer = cloneDeep(answer)
        updatedAnswer.score = Number((updatedAnswer.score * 100).toFixed())

        return updatedAnswer
      }) ?? [],
  )

  const hasError = computed(() => Boolean(embedError.value) || Boolean(searchError.value))
  const errorDetail = computed(() => embedError.value || searchError.value?.message || null)

  // Set while a refresh runs that the answers on screen survive, see #refreshKeepingAnswers.
  const keepingAnswers = ref(false)

  // The answers on screen do not match the ticket (yet): either the server is still producing the
  // embedding the search needs, or a request is on its way while an earlier result is displayed —
  // `loading` stays quiet in that second case, as it ignores a request that has a result behind it.
  const pending = computed(
    () =>
      rawPending.value ||
      (!keepingAnswers.value && queryHandler.loading().value && result.value !== undefined),
  )

  // Fire and forget: a failure surfaces via `searchError`, so the rejection is swallowed here and
  // the callers (ping, article count, retry, unlink) never produce an unhandled one.
  const refetch = ({ keepAnswers = false } = {}) => {
    // A refresh that is already waiting keeps its waiting state: it may be running because the
    // ticket content changed, and then the answers on screen no longer match the ticket — the later
    // refresh must not present them as the current ones.
    const refreshIsWaiting = queryHandler.loading().value && !keepingAnswers.value

    keepingAnswers.value = keepAnswers && !refreshIsWaiting

    queryHandler
      .refetch()
      .catch(() => {})
      .finally(() => {
        keepingAnswers.value = false
      })
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

  // A new article changes the ticket content the embedding is built from, so the search has to run
  // again while updates are enabled. Passive consumers can opt out together with the ping
  // subscription.
  useTicketArticleCountChange(
    () => toValue(articleCount),
    () => {
      if (!isSubscriptionEnabled.value) return

      embedError.value = null
      refetch()
    },
  )

  const retrySearch = () => {
    embedError.value = null
    refetch()
  }

  // Unlinking an answer makes it eligible as a suggestion again, but nothing else about the ticket
  // changed: the answers on screen are still the right ones, only one may join them. So this refresh
  // leaves them in place instead of showing the waiting state for the blink it takes.
  const refreshKeepingAnswers = () => {
    embedError.value = null
    refetch({ keepAnswers: true })
  }

  return { answers, loading, pending, hasError, errorDetail, retrySearch, refreshKeepingAnswers }
}
