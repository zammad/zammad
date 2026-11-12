// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import UserError from '#shared/errors/UserError.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import { useChatSessionAcceptMutation } from '#desktop/entities/chat/graphql/mutations/chatSessionAccept.api.ts'

import { useChatPreferencesStore } from '../stores/chatPreferences.ts'
import { useChatWindowsStore } from '../stores/chatWindows.ts'

export const useChatSessionAccept = () => {
  const { isLimitReached } = storeToRefs(useChatPreferencesStore())

  const { windowToReveal } = storeToRefs(useChatWindowsStore())

  const { notify } = useNotifications()

  const acceptMutation = new MutationHandler(useChatSessionAcceptMutation(), {
    errorNotificationMessage: __('The chat could not be accepted.'),
  })

  const isAccepting = acceptMutation.loading()

  // Hands the longest waiting customer of the topic, or of all topics the agent handles, to them. The
  //   state follows by itself: the accepted session shows up among the agent's own through the subscription.
  const accept = async (topicId?: string) => {
    if (isLimitReached.value || isAccepting.value) return undefined

    try {
      const result = await acceptMutation.send({ topicId })

      const session = result?.chatSessionAccept?.session

      if (session) windowToReveal.value = session.id

      return session
    } catch (error) {
      // The queue was emptied meanwhile, which is nothing the agent has to fix.
      if (error instanceof UserError) {
        notify({
          id: 'chat-accept-failed',
          type: NotificationTypes.Warn,
          message: error.getFirstErrorMessage(),
          unique: true,
        })
      }

      return undefined
    }
  }

  return { accept, isAccepting, isLimitReached }
}
