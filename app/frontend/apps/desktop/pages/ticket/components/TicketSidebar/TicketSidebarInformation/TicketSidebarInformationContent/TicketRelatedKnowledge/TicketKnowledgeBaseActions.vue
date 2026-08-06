<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

import { useTicketAiAssistanceEnqueueKnowledgeBaseAnswer } from '../composables/useTicketAiAssistanceEnqueueKnowledgeBaseAnswer.ts'

interface Props {
  showDraft: boolean
  isTicketEditable: boolean
  isLinkListLoading: boolean
}

defineProps<Props>()

const { ticket, ticketId } = useTicketInformation()

const newKnowledgeBaseAnswer = defineModel<boolean>('newKnowledgeBaseAnswer')
const FLYOUT_NAME = 'knowledge-base-ai-draft'

const { open } = useFlyout({
  name: FLYOUT_NAME,
  component: () => import('./TicketKnowledgeBaseAiDraftFlyout.vue'),
})

// The flyout renders outside this tree, so it cannot reach the ticket itself - it is handed over,
// like the link flyout gets its source ticket.
const openFlyout = () =>
  open({
    name: FLYOUT_NAME,
    ticket,
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
      <CommonLoader class="w-full" :loading="isLinkListLoading">
        <CommonButton
          v-if="isTicketEditable && !newKnowledgeBaseAnswer"
          v-tooltip="$t('Link knowledge base answer')"
          size="medium"
          class="ltr:ml-auto rtl:mr-auto"
          icon="plus-square-fill"
          @click="newKnowledgeBaseAnswer = true"
        />

        <template #skeleton>
          <CommonSkeleton class="size-8 ltr:ml-auto rtl:mr-auto" />
        </template>
      </CommonLoader>
    </slot>
  </div>
</template>
