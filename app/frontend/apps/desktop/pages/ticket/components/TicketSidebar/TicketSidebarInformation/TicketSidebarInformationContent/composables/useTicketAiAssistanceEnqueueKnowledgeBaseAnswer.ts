// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, type Ref } from 'vue'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import { useTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation } from '#desktop/pages/ticket/graphql/mutations/ticketAIAssistanceEnqueueKnowledgeBaseAnswer.api.ts'

const NOTIFICATION_ID = 'ticket-ai-knowledge-base-answers-notification'

const generations = ref(new Map<ID, Ref<boolean>>())

export const useTicketAiAssistanceEnqueueKnowledgeBaseAnswer = (
  ticketId: ID,
  flyoutName: string,
) => {
  const { notify } = useNotifications()

  const requestGenerationHandler = new MutationHandler(
    useTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation(),
    {
      errorShowNotification: false,
    },
  )

  const errorMessage = ref<string>()

  const requestDraft = async () => {
    if (generations.value.get(ticketId)?.value) return

    generations.value.set(ticketId, ref(true))

    try {
      await requestGenerationHandler.send({ ticketId })

      notify({
        id: NOTIFICATION_ID,
        type: NotificationTypes.Info,
        message: __(
          'A related knowledge base answer is being generated. You will be notified once the draft is ready.',
        ),
        durationMS: 8000,
      })

      closeFlyout(flyoutName)
    } catch (error) {
      errorMessage.value =
        (error as Error).message || __('Knowledge base draft could not be generated.')
    } finally {
      generations.value.delete(ticketId)
    }
  }

  const isGenerating = computed(() => generations.value.get(ticketId)?.value ?? false)

  return { requestDraft, isGenerating, errorMessage }
}
