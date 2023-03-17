// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'
import { useOnlineNotificationsCountSubscription } from '@shared/entities/online-notification/graphql/subscriptions/onlineNotificationsCount.api'
import { SubscriptionHandler } from '@shared/server/apollo/handler'
import { useSessionStore } from '@shared/stores/session'

export const useOnlineNotificationCount = () => {
  const unseenCount = ref(0)

  const { userId } = useSessionStore()

  const notificationsCountSubscription = new SubscriptionHandler(
    useOnlineNotificationsCountSubscription({ userId }),
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
