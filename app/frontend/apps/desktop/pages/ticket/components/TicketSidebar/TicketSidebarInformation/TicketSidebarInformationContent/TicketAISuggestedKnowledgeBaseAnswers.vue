<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'

import { useTicketArticleUpdatesSubscription } from '#shared/entities/ticket/graphql/subscriptions/ticketArticlesUpdates.api.ts'
import type { TicketAiRelatedKnowledgeBaseAnswersQuery } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { QueryHandler, SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { useTicketAiRelatedKnowledgeBaseAnswersQuery } from '#desktop/pages/ticket/graphql/queries/ticketAIRelatedKnowledgeBaseAnswers.api.ts'
import { useTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscription } from '#desktop/pages/ticket/graphql/subscriptions/ticketAIRelatedKnowledgeBaseAnswersUpdates.api.ts'

type RelatedAnswer = NonNullable<
  NonNullable<
    TicketAiRelatedKnowledgeBaseAnswersQuery['ticketAIRelatedKnowledgeBaseAnswers']['answers']
  >[number]
>

const { ticketId } = useTicketInformation()

// Synchronous search. Reruns automatically when the ticket changes (reactive variables).
const queryHandler = new QueryHandler(
  useTicketAiRelatedKnowledgeBaseAnswersQuery(() => ({ ticketId: ticketId.value })),
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
const answers = computed(() => search.value?.answers ?? [])

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

// Content-free ping: the embedding the search relies on may have settled. Always subscribed (not
// only while pending) so a fast-finishing job can never ping before we are ready.
const pingSubscription = new SubscriptionHandler(
  useTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscription(() => ({ ticketId: ticketId.value })),
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
  useTicketArticleUpdatesSubscription(() => ({ ticketId: ticketId.value })),
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

const answerLink = (translation: RelatedAnswer['translation']) => {
  const knowledgeBaseId = getIdFromGraphQLId(translation.answer.category.knowledgeBase.id)
  const { locale } = translation.kbLocale.systemLocale
  const answerId = getIdFromGraphQLId(translation.answer.id)
  return `/#knowledge_base/${knowledgeBaseId}/locale/${locale}/answer/${answerId}`
}
</script>

<template>
  <div class="flex w-full flex-col rounded-lg bg-blue-200 px-2.5 pt-1 pb-1.5 dark:bg-gray-700">
    <div class="space-y-2">
      <CommonLabel size="small" class="text-stone-200! dark:text-neutral-500!">
        {{ $t('Suggested by AI') }}
      </CommonLabel>

      <div v-if="hasError" class="flex flex-col items-end gap-3">
        <CommonAlert class="self-stretch" variant="danger">
          <div class="flex flex-col gap-1.5">
            <CommonLabel class="text-red-500 dark:text-red-500">
              {{
                $t(
                  'The suggestions could not be generated. Please try again later or contact your administrator.',
                )
              }}
            </CommonLabel>
            <CommonLabel v-if="errorDetail" class="text-red-500 dark:text-red-500">
              {{ $t('API server error: %s', $t(errorDetail)) }}
            </CommonLabel>
          </div>
        </CommonAlert>
        <CommonButton variant="tertiary" @click="retrySearch">{{ $t('Retry') }}</CommonButton>
      </div>

      <CommonLabel
        v-else-if="loading || pending"
        size="small"
        class="text-stone-200! dark:text-neutral-500!"
      >
        {{ $t('Searching for related answers…') }}
      </CommonLabel>

      <template v-else-if="answers.length">
        <CommonLink
          v-for="answer in answers"
          :key="answer.translation.id"
          :link="answerLink(answer.translation)"
          class="flex grow items-center gap-1.5"
        >
          <CommonIcon name="book" size="small" class="shrink-0" />
          <CommonLabel class="line-clamp-1! grow text-blue-800!">
            {{ answer.translation.title }}
          </CommonLabel>
        </CommonLink>
      </template>

      <CommonLabel v-else size="small" class="text-stone-200! dark:text-neutral-500!">
        {{ $t('No related knowledge base answers found.') }}
      </CommonLabel>
    </div>
  </div>
</template>
