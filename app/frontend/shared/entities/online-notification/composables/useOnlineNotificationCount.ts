// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { useOnlineNotificationsCountSubscription } from '#shared/entities/online-notification/graphql/subscriptions/onlineNotificationsCount.api.ts'
import { SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'

export const useOnlineNotificationCount = () => {
  const unseenCount = ref(0)

  const notificationsCountSubscription = new SubscriptionHandler(
    useOnlineNotificationsCountSubscription(),
  )

  notificationsCountSubscription.onResult((result) => {
    const { data } = result

    if (!data) return

    unseenCount.value = data.onlineNotificationsCount.unseenCount
  })

  return {
    notificationsCountSubscription,
    unseenCount,
  }
}
