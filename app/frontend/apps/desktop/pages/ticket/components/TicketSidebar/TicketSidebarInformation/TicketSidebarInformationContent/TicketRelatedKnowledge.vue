<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, toRef } from 'vue'

import type { KnowledgeBaseAnswerTranslationFragment } from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

import TicketKnowledgeBaseActions from './TicketRelatedKnowledge/TicketKnowledgeBaseActions.vue'
import TicketKnowledgeBaseAiSuggested from './TicketRelatedKnowledge/TicketKnowledgeBaseAiSuggested.vue'
import TicketKnowledgeBaseAnswerSkeleton from './TicketRelatedKnowledge/TicketKnowledgeBaseAnswerSkeleton.vue'
import TicketKnowledgeBaseLinks from './TicketRelatedKnowledge/TicketKnowledgeBaseLinks.vue'
import TicketNewKnowledgeBaseAnswer from './TicketRelatedKnowledge/TicketNewKnowledgeBaseAnswer.vue'

import type { RelatedAnswer } from './TicketRelatedKnowledge/types.ts'

interface Props {
  linkedAnswers: KnowledgeBaseAnswerTranslationFragment[]
  linkedAnswerIds: string[]
  targetType: string
  isLinkListLoading?: boolean
  showAiSuggestedAnswers: boolean
  aiSuggestedAnswers: RelatedAnswer[]
  isAiSuggestedAnswersLoading: boolean
  isAiSuggestedAnswersPending: boolean
  hasAiSuggestedAnswersError: boolean
  aiSuggestedAnswersErrorDetail: string | null
}

defineProps<Props>()

defineEmits<{
  'retry-ai-suggested-answers-search': []
}>()

const config = toRef(useApplicationStore(), 'config')

const { ticketId, isTicketEditable } = useTicketInformation()
const { hasPermission } = useSessionStore()

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
          :target-type="targetType"
          :is-ticket-editable="isTicketEditable"
        />
        <TicketKnowledgeBaseAiSuggested
          v-if="showAiSuggestedAnswers"
          :target-type="targetType"
          :answers="aiSuggestedAnswers"
          :loading="isAiSuggestedAnswersLoading"
          :pending="isAiSuggestedAnswersPending"
          :has-error="hasAiSuggestedAnswersError"
          :error-detail="aiSuggestedAnswersErrorDetail"
          :is-ticket-editable="isTicketEditable"
          @retry="$emit('retry-ai-suggested-answers-search')"
        />
      </div>

      <CommonLabel v-else size="small">
        {{ $t('No related knowledge base answer links.') }}
      </CommonLabel>

      <template #skeleton>
        <ul>
          <TicketKnowledgeBaseAnswerSkeleton />
        </ul>
      </template>
    </CommonLoader>

    <TicketKnowledgeBaseActions
      v-model:new-knowledge-base-answer="isNewKnowledgeBaseAnswerActive"
      :show-draft="showAIKnowledgeBaseDraft"
      :is-ticket-editable="isTicketEditable"
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
