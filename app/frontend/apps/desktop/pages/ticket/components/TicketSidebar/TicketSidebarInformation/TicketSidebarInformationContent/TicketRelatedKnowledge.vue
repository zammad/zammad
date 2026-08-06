<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, toRef } from 'vue'

import type { KnowledgeBaseAnswerTranslationFragment } from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

import { useKnowledgeBaseAnswerLinks } from './TicketRelatedKnowledge/composables/useKnowledgeBaseAnswerLinks.ts'
import TicketKnowledgeBaseActions from './TicketRelatedKnowledge/TicketKnowledgeBaseActions.vue'
import TicketKnowledgeBaseAiSuggested from './TicketRelatedKnowledge/TicketKnowledgeBaseAiSuggested.vue'
import TicketKnowledgeBaseAnswerSkeleton from './TicketRelatedKnowledge/TicketKnowledgeBaseAnswerSkeleton.vue'
import TicketKnowledgeBaseLinks from './TicketRelatedKnowledge/TicketKnowledgeBaseLinks.vue'
import TicketNewKnowledgeBaseAnswer from './TicketRelatedKnowledge/TicketNewKnowledgeBaseAnswer.vue'

import type { RelatedAnswer } from './TicketRelatedKnowledge/types.ts'

export interface Props {
  linkedAnswers: KnowledgeBaseAnswerTranslationFragment[]
  linkedAnswerIds: string[]
  targetType: string
  isLinkListLoading?: boolean
  showAiSuggestedAnswers: boolean
  showRelevanceScore: boolean
  aiSuggestedAnswers: RelatedAnswer[]
  isAiSuggestedAnswersLoading: boolean
  isAiSuggestedAnswersPending: boolean
  hasAiSuggestedAnswersError: boolean
  aiSuggestedAnswersErrorDetail: string | null
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'retry-ai-suggested-answers-search': []
  'refresh-ai-suggested-answers': []
}>()

const config = toRef(useApplicationStore(), 'config')

const { ticketId, isTicketEditable } = useTicketInformation()
const { hasPermission } = useSessionStore()

// An already-linked answer is no suggestion. The server drops them from the search result, but that
//   result arrives asynchronously, so keep the two lists disjoint here as well. Matched on the
//   answer rather than the translation, mirroring the server: linking one locale covers all of them.
const unlinkedAiSuggestedAnswers = computed(() => {
  const linkedAnswers = new Set(props.linkedAnswers.map((translation) => translation.answer.id))

  return props.aiSuggestedAnswers.filter(
    (answer) => !linkedAnswers.has(answer.translation.answer.id),
  )
})

const { unlinkAnswer } = useKnowledgeBaseAnswerLinks(ticketId.value, props.targetType)

// Unlinking makes the answer eligible as a suggestion again, but the search that excluded it ran on
//   the server, so it can only come back by re-running it. Nothing else about the ticket changed,
//   which is why this refresh keeps the current suggestions on screen rather than showing a waiting
//   state for the blink it takes.
const handleUnlinkAnswer = async (answerId: string) => {
  await unlinkAnswer(answerId)
  emit('refresh-ai-suggested-answers')
}

const isNewKnowledgeBaseAnswerActive = ref(false)

const vFocus = (element: HTMLDivElement) => element.querySelector('input')?.click()

const showAIKnowledgeBaseDraft = computed(
  () =>
    isTicketEditable.value &&
    hasPermission('knowledge_base.editor') &&
    config.value.ai_provider &&
    config.value.ai_assistance_kb_answer_from_ticket_generation,
)
</script>
<template>
  <div class="flex flex-col gap-3">
    <CommonLoader :loading="isLinkListLoading">
      <div
        v-if="linkedAnswers.length || showAiSuggestedAnswers"
        class="flex w-full flex-col gap-2 rounded-lg bg-blue-200 px-2.5 pt-2 pb-1 dark:bg-gray-700"
      >
        <TicketKnowledgeBaseLinks
          v-if="linkedAnswers?.length"
          :linked-answers="linkedAnswers"
          :is-ticket-editable="isTicketEditable"
          @unlink="handleUnlinkAnswer"
        />
        <TicketKnowledgeBaseAiSuggested
          v-if="showAiSuggestedAnswers"
          :target-type="targetType"
          :answers="unlinkedAiSuggestedAnswers"
          :loading="isAiSuggestedAnswersLoading"
          :pending="isAiSuggestedAnswersPending"
          :has-error="hasAiSuggestedAnswersError"
          :error-detail="aiSuggestedAnswersErrorDetail"
          :is-ticket-editable="isTicketEditable"
          :show-relevance-score="showRelevanceScore"
          @retry="$emit('retry-ai-suggested-answers-search')"
        />
      </div>

      <CommonLabel v-else size="small">
        {{ $t('No related knowledge base answer links.') }}
      </CommonLabel>

      <template #skeleton>
        <div
          class="flex w-full flex-col gap-2 rounded-lg bg-blue-200 px-2.5 pt-1 pb-1.5 dark:bg-gray-700"
        >
          <CommonSkeleton alternative-background class="h-3 w-12" />
          <ul class="space-y-2">
            <TicketKnowledgeBaseAnswerSkeleton />
            <TicketKnowledgeBaseAnswerSkeleton />
          </ul>
        </div>
      </template>
    </CommonLoader>

    <TicketKnowledgeBaseActions
      v-model:new-knowledge-base-answer="isNewKnowledgeBaseAnswerActive"
      :show-draft="showAIKnowledgeBaseDraft"
      :is-ticket-editable="isTicketEditable"
      :is-link-list-loading="isLinkListLoading"
    >
      <template v-if="isNewKnowledgeBaseAnswerActive" #default>
        <TicketNewKnowledgeBaseAnswer
          v-model:new-knowledge-base-answer="isNewKnowledgeBaseAnswerActive"
          v-focus
          :ticket-id="ticketId"
          :linked-answer-ids="linkedAnswerIds"
          :target-type="targetType"
        />
      </template>
    </TicketKnowledgeBaseActions>
  </div>
</template>
