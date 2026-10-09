// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { useOnlineNotificationsCountSubscription } from '#shared/entities/online-notification/graphql/subscriptions/onlineNotificationsCount.api.ts'
import { SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'

export const useOnlineNotificationCount = () => {
  const unseenCount = ref<number>()
  // Tags of the web pushes whose notifications are still unseen, see the mobile app.
  const unseenPushTags = ref<string[]>()

  const notificationsCountSubscription = new SubscriptionHandler(
    useOnlineNotificationsCountSubscription(),
  )

  notificationsCountSubscription.onResult((result) => {
    const { data } = result

    if (!data) return

    unseenCount.value = data.onlineNotificationsCount.unseenCount
    unseenPushTags.value = data.onlineNotificationsCount.unseenPushTags
  })

  return {
    notificationsCountSubscription,
    unseenCount,
    unseenPushTags,
  }
}
