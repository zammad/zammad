<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import type { KnowledgeBaseAnswerTranslationFragment } from '#shared/graphql/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { getKnowledgeBaseAnswerLink } from '#desktop/entities/knowledge-base/utils/knowledgeBaseAnswerLink.ts'

import TicketKnowledgeBaseAnswer from './TicketKnowledgeBaseAnswer.vue'

interface Props {
  linkedAnswers: KnowledgeBaseAnswerTranslationFragment[]
  isTicketEditable: boolean
  canInsertAnswer: boolean
}

defineProps<Props>()

defineEmits<{
  unlink: [answerId: string]
  insert: [answerId: string]
}>()
</script>

<template>
  <CommonLabel tag="h3" size="small" class="text-muted!">
    {{ $t('Linked') }}
  </CommonLabel>

  <ul>
    <TicketKnowledgeBaseAnswer
      v-for="translation in linkedAnswers"
      :key="translation.id"
      :translation="translation"
      :link="getKnowledgeBaseAnswerLink(translation)"
    >
      <template v-if="isTicketEditable" #action>
        <CommonButton
          v-if="canInsertAnswer"
          v-tooltip="$t('Insert knowledge base answer')"
          class="text-blue-800!"
          size="small"
          variant="tertiary"
          icon="editor-mention-knowledge-base"
          @click="$emit('insert', translation.id)"
        />
        <CommonButton
          v-tooltip="$t('Unlink knowledge base answer')"
          size="small"
          variant="remove"
          icon="x-lg"
          @click="$emit('unlink', translation.id)"
        />
      </template>
    </TicketKnowledgeBaseAnswer>
  </ul>
</template>
