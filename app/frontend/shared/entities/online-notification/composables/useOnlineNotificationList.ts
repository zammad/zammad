// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
import { computed } from 'vue'

import { useOnlineNotificationsQuery } from '#shared/entities/online-notification/graphql/queries/onlineNotifications.api.ts'
import type { OnlineNotification } from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { edgesToArray } from '#shared/utils/helpers.ts'

export const useOnlineNotificationList = () => {
  const notificationsQuery = new QueryHandler(useOnlineNotificationsQuery())

  const result = notificationsQuery.result()

  const notificationList = computed(
    () => edgesToArray(result.value?.onlineNotifications) as OnlineNotification[],
  )

  const isLoading = notificationsQuery.loadingWithoutCachedResult()

  const hasUnseenNotification = computed(() =>
    notificationList.value.some((notification) => !notification.seen),
  )

  const refetch = () => notificationsQuery.refetch()

  return {
    notificationList,
    hasUnseenNotification,
    refetch,
    loading: isLoading,
  }
}
