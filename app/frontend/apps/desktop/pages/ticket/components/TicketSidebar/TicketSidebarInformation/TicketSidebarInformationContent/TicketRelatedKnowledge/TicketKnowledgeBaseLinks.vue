<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import type { KnowledgeBaseAnswerTranslationFragment } from '#shared/graphql/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

import { useKnowledgeBaseAnswerLinks } from './composables/useKnowledgeBaseAnswerLinks.ts'
import TicketKnowledgeBaseAnswer from './TicketKnowledgeBaseAnswer.vue'
import { getKnowledgeBaseAnswerLink } from './utils/knowledgeBaseAnswerLink.ts'

interface Props {
  linkedAnswers: KnowledgeBaseAnswerTranslationFragment[]
  targetType: string
  isTicketEditable: boolean
}

const props = defineProps<Props>()

const { ticketId } = useTicketInformation()

const { unlinkAnswer } = useKnowledgeBaseAnswerLinks(ticketId.value, props.targetType)
</script>
<template>
  <CommonLabel tag="h3" size="small" class="text-stone-200! dark:text-neutral-500!">
    {{ $t('Linked') }}
  </CommonLabel>

  <ul>
    <TicketKnowledgeBaseAnswer
      v-for="translation in linkedAnswers"
      :key="translation.id"
      :translation="translation"
      :link="getKnowledgeBaseAnswerLink(translation)"
    >
      <template v-if="isTicketEditable" #action="{ hasOpenedViaLongPress }">
        <CommonButton
          v-tooltip="$t('Unlink knowledge base answer')"
          class="opacity-0 group-hover:opacity-100 focus-visible:opacity-100"
          :class="{ 'opacity-100': hasOpenedViaLongPress }"
          size="small"
          variant="remove"
          icon="x-lg"
          @click="unlinkAnswer(translation.id)"
        /> </template
    ></TicketKnowledgeBaseAnswer>
  </ul>
</template>
