// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { NotificationClassMap } from '#shared/components/CommonNotifications/types.ts'

// Provide your own map with the following keys, the values given here are just examples.
let notificationClasses: NotificationClassMap = {
  base: 'common-notification',
  baseContainer: 'common-notification-container',
  error: 'common-notification-error',
  info: 'common-notification-info',
  message: 'common-notification-message',
  success: 'common-notification-success',
  warn: 'common-notification-warn',
}

export const initializeNotificationClasses = (
  classes: NotificationClassMap,
) => {
  notificationClasses = classes
}

export const getNotificationClasses = () => notificationClasses
