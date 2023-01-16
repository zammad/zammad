// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'
import getUuid from '@shared/utils/getUuid'
import { NotificationTypes } from './types'
import type { NewNotification, Notification } from './types'

const notifications = ref<Notification[]>([])
const defaultNotificationDurationMS = 3000

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

    const newNotification: Notification = { id, timeout: 0, ...notification }

    if (notification.unique) {
      notifications.value = notifications.value.filter(
        (notification: Notification) => {
          const isSame = notification.id === id
          if (isSame) {
            window.clearTimeout(notification.timeout)
          }
          return !isSame
        },
      )
    }

    notifications.value.push(newNotification)

    if (!newNotification.persistent) {
      newNotification.timeout = window.setTimeout(() => {
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
