<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import type { KnowledgeBaseAnswerTranslationFragment } from '#shared/graphql/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import TicketKnowledgeBaseAnswer from './TicketKnowledgeBaseAnswer.vue'
import { getKnowledgeBaseAnswerLink } from './utils/knowledgeBaseAnswerLink.ts'

interface Props {
  linkedAnswers: KnowledgeBaseAnswerTranslationFragment[]
  isTicketEditable: boolean
}

defineProps<Props>()

defineEmits<{
  unlink: [answerId: string]
}>()

const { isTouchDevice } = useTouchDevice()
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
          :class="{
            'opacity-100': hasOpenedViaLongPress,
            'opacity-0 group-hover:opacity-100 focus-visible:opacity-100': !isTouchDevice,
          }"
          size="small"
          variant="remove"
          icon="x-lg"
          @click="$emit('unlink', translation.id)"
        /> </template
    ></TicketKnowledgeBaseAnswer>
  </ul>
</template>
