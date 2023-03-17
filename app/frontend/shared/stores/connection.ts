// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { ref } from 'vue'

import log from '@shared/utils/log'
import {
  NotificationTypes,
  useNotifications,
} from '@shared/components/CommonNotifications'

let connectionNotificationId: string

export const useConnectionStore = defineStore('connection', () => {
  const notifications = useNotifications()
  const connected = ref(false)

  const bringConnectionUp = (): void => {
    if (connected.value) return

    log.debug('Application connection just came up.')

    if (connectionNotificationId) {
      notifications.removeNotification(connectionNotificationId)
    }
    connected.value = true
  }

  const takeConnectionDown = (): void => {
    if (!connected.value) return

    log.debug('Application connection just went down.')

    connectionNotificationId = notifications.notify({
      message: __('The connection to the server was lost.'),
      type: NotificationTypes.Error,
      persistent: true,
    })
    connected.value = false
  }

  return {
    connected,
    bringConnectionUp,
    takeConnectionDown,
  }
})
