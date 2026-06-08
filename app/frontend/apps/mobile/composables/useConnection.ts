// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { handleConnection } from '#shared/server/connection.ts'

const notifications = useNotifications()

let connectionNotificationId: string | null = null

export const useConnection = () => {
  handleConnection(
    () => {
      connectionNotificationId = notifications.notify({
        id: 'connection-lost',
        message: __('The connection to the server was lost.'),
        type: NotificationTypes.Error,
        persistent: true,
      })
    },
    () => {
      if (connectionNotificationId) {
        notifications.removeNotification(connectionNotificationId)
        connectionNotificationId = null
      }
    },
    'active',
  )
}
