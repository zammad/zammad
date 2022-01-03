// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

export enum NotificationTypes {
  WARN = 'warn',
  SUCCESS = 'success',
  ERROR = 'error',
  INFO = 'info',
}

export interface NewNotificationInterface {
  id?: string
  message: string
  messagePlaceholder?: string[]
  type: NotificationTypes
  duration?: number
}

export interface NotificationInterface extends NewNotificationInterface {
  id: string
}
