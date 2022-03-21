// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { SetOptional } from 'type-fest'

export enum NotificationTypes {
  WARN = 'warn',
  SUCCESS = 'success',
  ERROR = 'error',
  INFO = 'info',
}

export interface Notification {
  id: string
  message: string
  messagePlaceholder?: string[]
  type: NotificationTypes
  durationMS?: number
  persistent?: boolean
  callback?: () => void
}

export type NewNotification = SetOptional<Notification, 'id'>
