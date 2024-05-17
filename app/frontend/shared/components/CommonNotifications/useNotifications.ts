// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import getUuid from '#shared/utils/getUuid.ts'

import { NotificationTypes } from './types.ts'

import type { NewNotification, Notification } from './types.ts'

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
    const { unique = true } = notification

    if (!id) {
      id = getUuid()
    }

    const newNotification: Notification = { id, timeout: 0, ...notification }

    if (unique) {
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

export { useNotifications }
