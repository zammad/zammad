// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'
import getUuid from '@shared/utils/getUuid'
import type { NewNotification } from './types'
import { type Notification, NotificationTypes } from './types'

const notifications = ref<Notification[]>([])
const defaultNotificationDurationMS = 5000

const removeNotification = (id: string) => {
  notifications.value = notifications.value.filter(
    (notification: Notification) => notification.id !== id,
  )
}

const clearAllNotifications = () => {
  notifications.value = []
}

const useNotifications = () => {
  const notify = (notification: NewNotification): string => {
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

  const hasErrors = () => {
    return notifications.value.some((notification) => {
      return notification.type === NotificationTypes.Error
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

export default useNotifications
