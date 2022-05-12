// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'
import getUuid from '@shared/utils/getUuid'
import { NewNotification, type Notification, NotificationTypes } from './types'

const notifications = ref<Notification[]>([])
const defaultNotificationDurationMS = 5000

function removeNotification(id: string) {
  notifications.value = notifications.value.filter(
    (notification: Notification) => notification.id !== id,
  )
}

function clearAllNotifications() {
  notifications.value = []
}

export default function useNotifications() {
  function notify(notification: NewNotification): string {
    let { id } = notification
    if (!id) {
      id = getUuid()
    }

    const newNotification: Notification = { id, ...notification }

    notifications.value.push(newNotification)

    if (!newNotification.persistent) {
      setTimeout(() => {
        removeNotification(newNotification.id)
      }, newNotification.durationMS || defaultNotificationDurationMS)
    }

    return newNotification.id
  }

  function hasErrors() {
    return notifications.value.some((notification) => {
      return notification.type === NotificationTypes.ERROR
    })
  }

  return {
    notify,
    notifications,
    removeNotification,
    clearAllNotifications,
    hasErrors,
  }
}
