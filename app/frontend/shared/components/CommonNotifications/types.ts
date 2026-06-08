// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { SetOptional } from 'type-fest'

export enum NotificationTypes {
  Warn = 'warn',
  Success = 'success',
  Error = 'error',
  Info = 'info',
}

export type NotificationClass = NotificationTypes | 'base' | 'baseContainer' | 'message'
export type NotificationClassMap = Record<NotificationClass, string>

export interface Notification {
  id: string
  message: string
  /**
   * This is not the timeout duration, but the ID of the timeout handler, which can be used to clear the timeout if
   *   needed (e.g. for unique notifications).
   *   In case you want to set the duration, use the `durationMS` property instead.
   */
  timeout: number
  type: NotificationTypes
  /**
   * Should notification be shown only once.
   * Multiple invocations with same ID will remove the previous notification.
   */
  unique?: boolean
  messagePlaceholder?: string[]
  /**
   * Duration in milliseconds after which the notification will be automatically removed.
   *   If not provided, the default duration of 3000ms will be used.
   */
  durationMS?: number
  persistent?: boolean
  currentProgress?: number
  maxProgress?: number
  actionLabel?: string
  actionCallback?: () => void
  /**
   * Will be called when the notification is removed, only by manual close action from the user
   */
  closeLabel?: string
  closeCallback?: () => void
}

export type NewNotification = SetOptional<Notification, 'id' | 'timeout'>
