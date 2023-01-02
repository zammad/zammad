// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { onMounted } from 'vue'
import {
  useNotifications,
  NotificationTypes,
} from '@shared/components/CommonNotifications'
import { usePushMessagesSubscription } from '@shared/graphql/subscriptions/pushMessages.api'
import type {
  PushMessagesSubscription,
  PushMessagesSubscriptionVariables,
} from '@shared/graphql/types'
import { SubscriptionHandler } from '@shared/server/apollo/handler'
import testFlags from '@shared/utils/testFlags'

let subscription: SubscriptionHandler<
  PushMessagesSubscription,
  PushMessagesSubscriptionVariables
>

const usePushMessages = () => {
  const notify = (message: string) => {
    useNotifications().notify({
      message,
      type: NotificationTypes.Warn,
      persistent: true,
    })
  }

  onMounted(() => {
    if (subscription) return

    subscription = new SubscriptionHandler(usePushMessagesSubscription())
    subscription.onResult((result) => {
      const message = result.data?.pushMessages
      if (!message?.title && !message?.text) {
        testFlags.set('usePushMessagesSubscription.subscribed')
        return
      }
      notify(`${message.title}: ${message.text}`)
    })
  })
}

export default usePushMessages
