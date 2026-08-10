<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'

import { useAiSuggestedAnswersAvailability } from '../composables/useAiSuggestedAnswersAvailability.ts'
import { useKnowledgeBaseAiSuggestedAnswers } from '../composables/useKnowledgeBaseAiSuggestedAnswers.ts'
import { useTicketAiAssistanceEnqueueKnowledgeBaseAnswer } from '../composables/useTicketAiAssistanceEnqueueKnowledgeBaseAnswer.ts'

import TicketKnowledgeBaseAiDraftFlyoutAnswer from './TicketKnowledgeBaseAiDraftFlyoutAnswer.vue'
import TicketKnowledgeBaseAiDraftFlyoutAnswerSkeleton from './TicketKnowledgeBaseAiDraftFlyoutAnswerSkeleton.vue'

interface Props {
  name: string
  // Handed over by the opener: a flyout renders outside the ticket detail view and cannot inject it.
  ticket: TicketById
}

const props = defineProps<Props>()

const ticketId = toRef(() => props.ticket.id)

const {
  requestDraft,
  isGenerating,
  errorMessage: draftGenerationError,
} = useTicketAiAssistanceEnqueueKnowledgeBaseAnswer(ticketId.value, props.name)

const { showRelevanceScore } = useAiSuggestedAnswersAvailability(
  () => props.ticket.policy.agentReadAccess,
)

// Deciding whether to write a new answer means looking at every answer that could already cover the
// topic — drafts and archived ones included, and the ones already linked to the ticket, which the
// sidebar list leaves out because it shows them separately. That widens the search compared to the
// sidebar list, so the flyout has its own result and drives it itself — including the ping
// subscription that resolves a pending embedding.
//
// It searches from scratch on every open (`network-only`): the cached answers of an earlier open can
// predate the ticket's current content, and a decision as final as "no answer covers this, write a
// new one" must not be made on them. A short wait is the better trade here.
const { answers, loading, pending, hasError, errorDetail, retrySearch } =
  useKnowledgeBaseAiSuggestedAnswers(ticketId, {
    includeDraftsAndArchived: true,
    includeLinkedAnswers: true,
    fetchPolicy: 'network-only',
    articleCount: () => props.ticket.articleCount,
  })
</script>

<template>
  <CommonFlyout
    no-close-on-action
    :footer-action-options="{
      actionLabel: __('Generate'),
      actionButton: {
        variant: 'submit',
        disabled: isGenerating || loading || pending || !!draftGenerationError,
      },
    }"
    :name="name"
    @action="requestDraft"
  >
    <template #header>
      <CommonLabel
        :id="`flyout-${name}-title`"
        tag="h2"
        class="ai-stripe grow gap-1.5 before:absolute before:inset-x-3 before:bottom-0 before:w-[calc(100%-var(--space-3))]"
        size="large"
        prefix-icon="book"
        icon-color="text-blue-800"
      >
        {{ $t('Generate knowledge base answer from this ticket') }}
      </CommonLabel>
    </template>

    <section class="@container space-y-4 pt-8 pb-3">
      <CommonAlert v-if="draftGenerationError" variant="danger">
        {{ $t(draftGenerationError) }}
      </CommonAlert>

      <template v-else>
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
              <CommonLabel v-if="errorDetail" class="wrap-anywhere text-red-500 dark:text-red-500">
                {{ $t('API server error: %s', $t(errorDetail)) }}
              </CommonLabel>
            </div>
          </CommonAlert>
          <CommonButton variant="tertiary" @click="retrySearch">{{ $t('Retry') }}</CommonButton>
        </div>

        <CommonLoader v-else :loading="loading || pending">
          <div v-if="answers.length" class="space-y-4">
            <CommonLabel tag="p">{{
              $t(
                'Before creating a new knowledge base answer, please check whether an existing answer already covers the solution for this ticket.',
              )
            }}</CommonLabel>

            <div class="space-y-2.5 rounded-lg bg-blue-200 px-2.5 pt-2 pb-1 dark:bg-gray-700">
              <CommonLabel tag="h3" size="small" class="text-stone-200! dark:text-neutral-500!">
                {{ $t('AI suggested knowledge') }}
              </CommonLabel>

              <ul class="divide-y divide-neutral-100 dark:divide-gray-900">
                <TicketKnowledgeBaseAiDraftFlyoutAnswer
                  v-for="answer in answers"
                  :key="answer.translation.id"
                  :answer="answer"
                  :show-relevance-score="showRelevanceScore"
                />
              </ul>
            </div>

            <CommonLabel tag="p">{{
              $t('None of the existing knowledge base answers fit your ticket?')
            }}</CommonLabel>
          </div>

          <div v-else class="space-y-2.5 rounded-lg bg-blue-200 px-2.5 py-2 dark:bg-gray-700">
            <CommonLabel tag="h3" size="small" class="text-stone-200! dark:text-neutral-500!">
              {{ $t('AI suggested knowledge') }}
            </CommonLabel>
            <CommonLabel tag="p">
              {{
                $t(
                  'No existing knowledge base answers match this topic. Generate a new answer to continue.',
                )
              }}
            </CommonLabel>
          </div>

          <template #skeleton>
            <div class="space-y-2.5 rounded-lg bg-blue-200 px-2.5 pt-2 pb-1 dark:bg-gray-700">
              <CommonLabel size="small" class="text-stone-200! dark:text-neutral-500!" tag="h3">
                {{ $t('AI suggested knowledge') }}
              </CommonLabel>

              <ul class="divide-y divide-neutral-100 dark:divide-gray-900">
                <!-- Only the first placeholder carries the label, so the loading state keeps a single
                accessible name. -->
                <TicketKnowledgeBaseAiDraftFlyoutAnswerSkeleton
                  v-for="index in 3"
                  :key="index"
                  :label="index === 1 ? __('Searching for related answers…') : undefined"
                />
              </ul>
            </div>
          </template>
        </CommonLoader>
      </template>
    </section>
  </CommonFlyout>
</template>
