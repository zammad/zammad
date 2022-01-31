// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { v4 as uuid } from 'uuid'
import { ref } from 'vue'
import type {
  NewNotificationInterface,
  NotificationInterface,
} from '@common/types/notification'

const notifications = ref<NotificationInterface[]>([])
const defaultNotificationDurationMS = 5000

function removeNotification(id: string) {
  notifications.value = notifications.value.filter(
    (notification: NotificationInterface) => notification.id !== id,
  )
}

function clearAllNotifications() {
  notifications.value = []
}

export default function useNotifications() {
  function notify(notification: NewNotificationInterface): string {
    let { id } = notification
    if (!id) {
      id = uuid()
    }

    const newNotification: NotificationInterface = { id, ...notification }

    notifications.value.push(newNotification)

    if (!newNotification.persistent) {
      setTimeout(() => {
        removeNotification(newNotification.id)
      }, newNotification.durationMS || defaultNotificationDurationMS)
    }

    return newNotification.id
  }

  return {
    notify,
    notifications,
    removeNotification,
    clearAllNotifications,
  }
}
