<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

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
  ticketId: string
  activeSidebar: () => string | null
}

const props = defineProps<Props>()

const {
  requestDraft,
  isGenerating,
  errorMessage: draftGenerationError,
} = useTicketAiAssistanceEnqueueKnowledgeBaseAnswer(props.ticketId, props.name)

const { showAiSuggestedAnswers } = useAiSuggestedAnswersAvailability()

const isSuggestedAnswersListVisible = computed(
  () => showAiSuggestedAnswers.value && props.activeSidebar() === 'information',
)

// The sidebar list runs the very same search. While it is visible it owns the live result: it holds
// the subscriptions and re-runs the query into the same cache entry we watch, so we only read from it
// and stay in sync for free. With the list hidden the flyout is the only consumer, so it has to
// drive the search itself — including the ping subscription that resolves a pending embedding.
const { answers, loading, pending, hasError, errorDetail, retrySearch } =
  useKnowledgeBaseAiSuggestedAnswers(toRef(props, 'ticketId'), {
    subscriptionEnabled: computed(() => !isSuggestedAnswersListVisible.value),
    fetchPolicy: computed(() =>
      isSuggestedAnswersListVisible.value ? 'cache-first' : 'cache-and-network',
    ),
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
              <CommonLabel v-if="errorDetail" class="text-red-500 dark:text-red-500">
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
