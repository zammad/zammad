<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { useTicketSidebar } from '#desktop/pages/ticket/composables/useTicketSidebar.ts'

import { useTicketAiAssistanceEnqueueKnowledgeBaseAnswer } from '../composables/useTicketAiAssistanceEnqueueKnowledgeBaseAnswer.ts'

interface Props {
  showDraft: boolean
  isTicketEditable: boolean
}

defineProps<Props>()

const { ticketId } = useTicketInformation()

const newKnowledgeBaseAnswer = defineModel<boolean>('newKnowledgeBaseAnswer')
const FLYOUT_NAME = 'knowledge-base-ai-draft'

const { open } = useFlyout({
  name: FLYOUT_NAME,
  component: () => import('./TicketKnowledgeBaseAiDraftFlyout.vue'),
})

const { activeSidebar } = useTicketSidebar()

const openFlyout = () =>
  open({
    name: FLYOUT_NAME,
    ticketId: ticketId.value,
    activeSidebar: () => activeSidebar.value,
  })

const { isGenerating } = useTicketAiAssistanceEnqueueKnowledgeBaseAnswer(
  ticketId.value,
  FLYOUT_NAME,
)
</script>

<template>
  <div class="flex">
    <slot>
      <CommonButton
        v-if="showDraft"
        type="button"
        size="small"
        :disabled="isGenerating"
        prefix-icon="ai-knowledge-base"
        icon-class="text-blue-800"
        class="relative ai-stripe bg-green-200! text-gray-300! before:absolute before:bottom-0 before:w-[85%] hover:bg-green-200! dark:bg-gray-600! dark:text-neutral-400! dark:hover:bg-gray-600!"
        @click="openFlyout"
      >
        {{ $t('Add AI draft') }}
      </CommonButton>
      <CommonButton
        v-if="isTicketEditable && !newKnowledgeBaseAnswer"
        v-tooltip="$t('Link knowledge base answer')"
        size="medium"
        class="ltr:ml-auto rtl:mr-auto"
        icon="plus-square-fill"
        @click="newKnowledgeBaseAnswer = true"
      />
    </slot>
  </div>
</template>
