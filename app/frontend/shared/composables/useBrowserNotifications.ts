// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { usePermission } from '@vueuse/core'
import { computed } from 'vue'

export const useBrowserNotifications = () => {
  const notificationPermission = usePermission('notifications')

  const isGranted = computed(() => notificationPermission.value === 'granted')

  const requestNotification = async () =>
    'requestPermission' in Notification
      ? Notification.requestPermission()
      : Promise.resolve()

  return {
    notificationPermission,
    isGranted,
    requestNotification,
  }
}
