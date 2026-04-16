<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { useTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation } from '#desktop/pages/ticket/graphql/mutations/ticketAIAssistanceEnqueueKnowledgeBaseAnswer.api.ts'

const NOTIFICATION_ID = 'ticket-ai-knowledge-base-answers-notification'

const isGenerating = ref(false)

const { ticketId } = useTicketInformation()
const { notify } = useNotifications()

const requestGenerationHandler = new MutationHandler(
  useTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation(),
  {
    errorShowNotification: false,
  },
)

const requestDraft = async () => {
  if (isGenerating.value) return

  isGenerating.value = true

  try {
    await requestGenerationHandler.send({ ticketId: ticketId.value })

    notify({
      id: NOTIFICATION_ID,
      type: NotificationTypes.Info,
      message: __('Generating knowledge base answer from related ticket…'),
    })
  } catch (error) {
    notify({
      id: NOTIFICATION_ID,
      type: NotificationTypes.Error,
      message: (error as Error).message || __('Knowledge base draft could not be generated.'),
    })
  } finally {
    isGenerating.value = false
  }
}
</script>

<template>
  <div class="flex">
    <CommonButton
      type="button"
      size="small"
      prefix-icon="ai-knowledge-base"
      class="relative ai-stripe bg-green-200! text-gray-300! before:absolute before:bottom-0 before:w-[85%] hover:bg-green-200! dark:bg-gray-600! dark:text-neutral-400! dark:hover:bg-gray-600!"
      :disabled="isGenerating"
      @click="requestDraft"
    >
      {{ $t('Generate Related AI Answer') }}
    </CommonButton>
  </div>
</template>
