<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { getKnowledgeBaseAnswerLink } from '#desktop/entities/knowledge-base/utils/knowledgeBaseAnswerLink.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

import { useKnowledgeBaseAnswerLinks } from './composables/useKnowledgeBaseAnswerLinks.ts'
import TicketKnowledgeBaseAiSuggestionsError from './TicketKnowledgeBaseAiSuggestionsError.vue'
import TicketKnowledgeBaseAnswer from './TicketKnowledgeBaseAnswer.vue'
import TicketKnowledgeBaseAnswerSkeleton from './TicketKnowledgeBaseAnswerSkeleton.vue'

import type { RelatedAnswer } from './types.ts'

export interface Props {
  targetType: string
  answers: RelatedAnswer[]
  loading: boolean
  pending: boolean
  hasError: boolean
  errorDetail: string | null
  isTicketEditable: boolean
  canInsertAnswer: boolean
  showRelevanceScore: boolean
}

const props = defineProps<Props>()

defineEmits<{
  retry: []
  insert: [answerId: string]
}>()

const { ticketId } = useTicketInformation()

const { linkAnswer } = useKnowledgeBaseAnswerLinks(ticketId.value, props.targetType)
</script>

<template>
  <CommonLabel tag="h3" size="small" class="text-muted!">
    {{ $t('Suggested') }}
  </CommonLabel>
  <TicketKnowledgeBaseAiSuggestionsError
    v-if="hasError"
    class="mb-1"
    :error-detail="errorDetail"
    @retry="$emit('retry')"
  />

  <CommonLoader v-else :loading="loading || pending">
    <ul v-if="answers.length" class="mb-1">
      <TicketKnowledgeBaseAnswer
        v-for="answer in answers"
        :key="answer.translation.id"
        :translation="answer.translation"
        :link="getKnowledgeBaseAnswerLink(answer.translation)"
      >
        <template v-if="showRelevanceScore" #link-trailing>
          <CommonLabel
            v-tooltip.supportive="$t('Relevance score')"
            size="small"
            class="text-muted!"
          >
            {{ `${answer.score}%` }}
          </CommonLabel>
        </template>
        <template v-if="isTicketEditable" #action>
          <CommonButton
            v-if="canInsertAnswer"
            v-tooltip="$t('Insert knowledge base answer')"
            class="text-blue-800!"
            size="small"
            variant="tertiary"
            icon="editor-mention-knowledge-base"
            @click="$emit('insert', answer.translation.id)"
          />
          <CommonButton
            v-tooltip="$t('Link knowledge base answer')"
            class="text-blue-800!"
            size="small"
            variant="tertiary"
            icon="plus-square-fill"
            @click="linkAnswer(answer.translation.id)"
          />
        </template>
      </TicketKnowledgeBaseAnswer>
    </ul>

    <!-- Not "no answers found": the best matches may all be linked already, and those are listed
    above rather than suggested again. -->
    <CommonLabel v-else class="mb-1" size="small">
      {{ $t('No suggestions.') }}
    </CommonLabel>

    <template #skeleton>
      <ul>
        <TicketKnowledgeBaseAnswerSkeleton :label="__('Searching for related answers…')" />
      </ul>
    </template>
  </CommonLoader>
</template>
