// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { initializeAlertClasses } from '#shared/initializer/initializeAlertClasses.ts'
import { initializeLinkClasses } from '#shared/initializer/initializeLinkClasses.ts'
import { initializeNotificationClasses } from '#shared/initializer/initializeNotificationClasses.ts'

export const initializeGlobalComponentStyles = () => {
  initializeAlertClasses({
    base: 'alert w-auto text-sm',
    success: 'alert-success bg-green-300 dark:bg-green-900 text-green-500',
    info: 'alert-info bg-blue-500 dark:bg-blue-950 text-blue-800',
    warning: 'alert-warning bg-yellow-50 dark:bg-yellow-900 text-yellow-600',
    danger: 'alert-error bg-pink-100 dark:bg-red-900 text-red-500',
    link: 'hover:underline',
  })

  initializeLinkClasses({
    base: 'link link-hover text-blue-800 focus-visible:rounded-sm focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800',
  })

  initializeNotificationClasses({
    base: 'alert rounded-lg gap-1.5 p-2 border-transparent',
    baseContainer: 'mx-auto',
    error: 'alert-error bg-pink-100 dark:bg-red-900 text-red-500',
    info: 'alert-info bg-blue-500 dark:bg-blue-950 text-blue-800',
    message: '',
    success: 'alert-success bg-green-300 dark:bg-green-900 text-green-500',
    warn: 'alert-warning bg-yellow-50 dark:bg-yellow-900 text-yellow-600',
  })
}
