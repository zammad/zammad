// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { initializeAlertClasses } from '#shared/initializer/initializeAlertClasses.ts'
import { initializeAvatarClasses } from '#shared/initializer/initializeAvatarClasses.ts'
import { initializeUserAvatarClasses } from '#shared/initializer/initializeUserAvatarClasses.ts'
import { initializeOrganizationAvatarClasses } from '#shared/initializer/initializeOrganizationAvatarClasses.ts'
import { initializeBadgeClasses } from '#shared/initializer/initializeBadgeClasses.ts'
import { initializeLinkClasses } from '#shared/initializer/initializeLinkClasses.ts'
import { initializeNotificationClasses } from '#shared/initializer/initializeNotificationClasses.ts'

export const initializeGlobalComponentStyles = () => {
  initializeBadgeClasses({
    base: 'inline-flex justify-center items-center border-0',
    success:
      'bg-green-300 text-green-500 dark:bg-green-900 dark:text-green-500',
    info: 'bg-blue-500 text-blue-800 dark:bg-blue-950 dark:text-blue-800',
    warning:
      'bg-yellow-50 text-yellow-600 dark:bg-yellow-900 dark:text-yellow-600',
    danger: 'bg-pink-100 text-red-500 dark:bg-red-900 dark:text-red-500',
    neutral:
      'bg-blue-200 text-stone-200 dark:bg-gray-700 dark:text-neutral-500',
    custom: 'badge-custom',
  })

  initializeAlertClasses({
    base: 'grid gap-4 text-center md:text-start text-sm items-center justify-center md:justify-start grid-flow-row md:grid-flow-col md:grid-cols-[auto_minmax(auto,_1fr)] w-full md:w-auto',
    success: 'bg-green-300 dark:bg-green-900 text-green-500',
    info: 'bg-blue-500 dark:bg-blue-950 text-blue-800',
    warning: 'bg-yellow-50 dark:bg-yellow-900 text-yellow-600',
    danger: 'bg-pink-100 dark:bg-red-900 text-red-500',
    link: 'hover:underline',
  })

  // TODO: check correct classes
  initializeAvatarClasses({
    base: 'border -:border-neutral-100 dark:-:border-gray-900 text-black',
    vipOrganization: 'text-neutral-400',
    vipUser: 'text-yellow-300',
  })

  initializeUserAvatarClasses({
    backgroundColors: [
      'bg-neutral-500',
      'bg-red-500',
      'bg-yellow-300',
      'bg-blue-700',
      'bg-green-500',
      'bg-pink-300',
      'bg-yellow-600',
    ],
  })

  initializeOrganizationAvatarClasses({
    backgroundColor: 'bg-green-100 dark:bg-gray-200',
  })

  initializeLinkClasses({
    base: 'link link-hover text-blue-800 focus-visible:rounded-sm focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800',
  })

  initializeNotificationClasses({
    base: 'grid gap-4 text-center md:text-start text-sm items-center justify-center md:justify-start grid-flow-row md:grid-flow-col md:grid-cols-[auto_minmax(auto,_1fr)] w-full rounded-lg gap-1.5 p-2 border-transparent',
    baseContainer: 'mx-auto',
    error: 'bg-pink-100 dark:bg-red-900 text-red-500',
    info: 'bg-blue-500 dark:bg-blue-950 text-blue-800',
    message: '',
    success: 'bg-green-300 dark:bg-green-900 text-green-500',
    warn: 'bg-yellow-50 dark:bg-yellow-900 text-yellow-600',
  })
}
