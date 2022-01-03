// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { v4 as uuid } from 'uuid'
import { ref } from 'vue'
import type {
  NewNotificationInterface,
  NotificationInterface,
} from '@common/types/notification'

const notifications = ref<NotificationInterface[]>([])
const defaultNotificationDuration = 5000

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
    // TODO: Check different solution for the optional id in the interface, but required field in the removeNotification function.
    let { id } = notification
    if (!id) {
      id = uuid()
    }

    const newNotification: NotificationInterface = { id, ...notification }

    notifications.value.push(newNotification)

    setTimeout(() => {
      removeNotification(newNotification.id)
    }, newNotification.duration || defaultNotificationDuration)

    return newNotification.id
  }

  return {
    notify,
    notifications,
    clearAllNotifications,
  }
}
