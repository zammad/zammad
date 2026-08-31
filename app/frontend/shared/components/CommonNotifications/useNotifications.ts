// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref, toRaw } from 'vue'

import getUuid from '#shared/utils/getUuid.ts'

import { NotificationTypes } from './types.ts'

import type { NewNotification, Notification } from './types.ts'

const notifications = ref<Notification[]>([])
const defaultNotificationDurationMS = 3000

// Pending auto-dismiss timers must be cancelled whenever a notification goes away, otherwise a
// leftover timer would later remove an unrelated notification that reuses the same id.
const cancelNotificationTimeout = (notification: Notification) => {
  window.clearTimeout(notification.timeout)
}

const removeNotification = (id: string) => {
  notifications.value = notifications.value.filter((notification: Notification) => {
    if (notification.id !== id) return true

    cancelNotificationTimeout(notification)
    return false
  })
}

const clearAllNotifications = () => {
  notifications.value.forEach(cancelNotificationTimeout)
  notifications.value = []
}

const useNotifications = () => {
  const notify = (notification: NewNotification): string => {
    let { id } = notification

    const { unique = true, actionLabel, actionCallback, persistent } = notification

    /* eslint-disable zammad/zammad-detect-translatable-string */
    if (actionLabel && !actionCallback) {
      throw new Error('An action callback must be provided when action label is set.')
    } else if (!actionLabel && actionCallback) {
      throw new Error('An action label must be provided when action callback is set.')
    } else if (actionLabel && actionCallback && !persistent) {
      throw new Error('A notification with an action must be made persistent.')
    }
    /* eslint-enable zammad/zammad-detect-translatable-string */

    if (!id) id = getUuid()

    const newNotification: Notification = { id, timeout: 0, ...notification }

    if (unique) {
      notifications.value = notifications.value.filter((notification: Notification) => {
        const isSame = notification.id === id
        if (isSame) {
          cancelNotificationTimeout(notification)
        }
        return !isSame
      })
    }

    notifications.value.push(newNotification)

    if (!newNotification.persistent) {
      newNotification.timeout = window.setTimeout(() => {
        notifications.value = notifications.value.filter(
          (notification) => toRaw(notification) !== newNotification,
        )
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
