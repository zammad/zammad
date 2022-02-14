// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import useNotifications from '@common/composables/useNotifications'
import { usePushMessagesSubscription } from '@common/graphql/api'
import {
  PushMessagesSubscription,
  PushMessagesSubscriptionVariables,
} from '@common/graphql/types'
import { SubscriptionHandler } from '@common/server/apollo/handler'
import { NotificationTypes } from '@common/types/notification'
import { onMounted } from 'vue'

let subscription: SubscriptionHandler<
  PushMessagesSubscription,
  PushMessagesSubscriptionVariables
>

export default function usePushMessages() {
  function notify(message: string) {
    useNotifications().notify({
      message,
      type: NotificationTypes.WARN,
      persistent: true,
    })
  }

  onMounted(() => {
    if (subscription) return

    subscription = new SubscriptionHandler(usePushMessagesSubscription())
    subscription.onResult((result) => {
      const message = result.data?.pushMessages
      if (!message?.title && !message?.text) return
      notify(`${message.title}: ${message.text}`)
    })
  })
}
