// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { initializeEditorColorMenuClasses } from '#shared/components/Form/fields/FieldEditor/FieldEditorColorMenu/initializeEditorColorMenu.ts'
import { initializeAlertClasses } from '#shared/initializer/initializeAlertClasses.ts'
import { initializeAvatarClasses } from '#shared/initializer/initializeAvatarClasses.ts'
import { initializeBadgeClasses } from '#shared/initializer/initializeBadgeClasses.ts'
import { initializeFilePreviewClasses } from '#shared/initializer/initializeFilePreviewClasses.ts'
import { initializeLinkClasses } from '#shared/initializer/initializeLinkClasses.ts'
import { initializeNotificationClasses } from '#shared/initializer/initializeNotificationClasses.ts'
import { initializeOrganizationAvatarClasses } from '#shared/initializer/initializeOrganizationAvatarClasses.ts'
import { initializePopoverClasses } from '#shared/initializer/initializePopover.ts'
import { initializeUserAvatarClasses } from '#shared/initializer/initializeUserAvatarClasses.ts'

export const initializeGlobalComponentStyles = () => {
  initializeBadgeClasses({
    base: '-:inline-flex justify-center items-center border-0',
    success:
      'bg-green-300 text-green-500 dark:bg-green-900 dark:text-green-500',
    info: 'bg-blue-500 text-blue-800 dark:bg-blue-950 dark:text-blue-800',
    tertiary:
      'bg-blue-200 text-stone-200 dark:bg-gray-700  dark:text-neutral-500',
    warning:
      'bg-yellow-50 text-yellow-600 dark:bg-yellow-900 dark:text-yellow-600',
    danger: 'bg-pink-100 text-red-500 dark:bg-red-900 dark:text-red-500',
    neutral:
      'text-gray-100 bg-neutral-50 dark:text-neutral-400 dark:bg-gray-500',
    custom: 'badge-custom',
  })

  initializeAlertClasses({
    base: 'grid gap-1.5 text-center md:text-start text-sm items-start justify-center md:justify-start grid-flow-row md:grid-flow-col md:grid-cols-[auto_minmax(auto,_1fr)] w-full md:w-auto',
    success: 'bg-green-300 dark:bg-green-900 text-green-500',
    info: 'bg-blue-500 dark:bg-blue-950 text-blue-800',
    warning: 'bg-yellow-50 dark:bg-yellow-900 text-yellow-600',
    danger: 'bg-pink-100 dark:bg-red-900 text-red-500',
  })

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
    base: 'bg-green-100 dark:bg-gray-200 text-stone-200 dark:text-gray-700',
    inactive: 'opacity-30',
  })

  initializeLinkClasses({
    base: 'cursor-pointer no-underline hover:underline text-blue-800 focus-visible:rounded-sm focus-visible:outline-1 focus-visible:outline-none focus-visible:outline-offset-1 focus-visible:outline-blue-800',
  })

  initializeNotificationClasses({
    base: 'grid gap-1.5 text-center md:text-start text-sm items-center justify-center md:justify-start grid-flow-row md:grid-flow-col md:grid-cols-[auto_minmax(auto,_1fr)] w-full rounded-lg p-2 border-transparent',
    baseContainer: 'mx-auto',
    error: 'bg-pink-100 dark:bg-red-900 text-red-500',
    info: 'bg-blue-500 dark:bg-blue-950 text-blue-800',
    message: '',
    success: 'bg-green-300 dark:bg-green-900 text-green-500',
    warn: 'bg-yellow-50 dark:bg-yellow-900 text-yellow-600',
  })

  initializePopoverClasses({
    base: 'min-h-9 rounded-xl border border-neutral-100 bg-neutral-50 antialiased dark:border-gray-900 dark:bg-gray-500',
    arrow:
      'h-[22px] w-[22px] border border-neutral-100 bg-neutral-50 dark:border-gray-900 dark:bg-gray-500',
  })

  initializeEditorColorMenuClasses({
    colorSchemeList: {
      base: 'border-b border-stone-200 dark:border-neutral-500 pb-1',
      button: 'p-2',
    },
  })

  initializeFilePreviewClasses({
    base: 'dark:text-white text-black text-sm leading-snug',
    wrapper: 'p-2.5',
    preview:
      'hover:outline hover:outline-1 hover:outline-offset-1 hover:outline-blue-600 focus:outline-none focus:outline-0 focus:outline-offset-0 focus:hover:outline-1 focus:hover:outline-offset-1 focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:hover:outline-blue-900',
    link: 'hover:rounded-sm hover:no-underline hover:outline-1 hover:outline-offset-1 hover:outline-blue-600 dark:hover:outline-blue-900',
    size: '-:dark:text-neutral-500 -:text-stone-400 text-xs leading-snug',
    icon: '-:dark:text-neutral-500 -:text-stone-400',
  })
}
