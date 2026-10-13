// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { useOnlineNotificationsCountSubscription } from '#shared/entities/online-notification/graphql/subscriptions/onlineNotificationsCount.api.ts'
import { SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'

// The push tags are for the mobile app, which closes seen pushes with them.
//   They cost the server queries of their own, so they are opt-in.
export const useOnlineNotificationCount = ({ withPushTags = false } = {}) => {
  const unseenCount = ref<number>()
  const unseenPushTags = ref<string[]>()

  const notificationsCountSubscription = new SubscriptionHandler(
    useOnlineNotificationsCountSubscription({ withPushTags }),
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
