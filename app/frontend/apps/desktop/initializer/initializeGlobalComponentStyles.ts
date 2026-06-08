// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { initializeProgressBarClasses } from '#shared/components/CommonProgressBar/initializeProgressBarClasses.ts'
import { initializeAiAssistantTextToolsLoadingBannerClasses } from '#shared/components/Form/fields/FieldEditor/features/ai-assistant-text-tools/AiAssistantLoadingBanner/initializeAiAssistantTextToolsLoadingBannerClasses.ts'
import { initializeAiAssistantTextToolsClasses } from '#shared/components/Form/fields/FieldEditor/features/ai-assistant-text-tools/AiAssistantTextTools/initializeAiAssistantTextToolsClasses.ts'
import { initializeEditorColorMenuClasses } from '#shared/components/Form/fields/FieldEditor/features/color-picker/initializeEditorColorMenuClasses.ts'
import { initializeEditorLinkFormClasses } from '#shared/components/Form/fields/FieldEditor/features/link/initializeLinkFormClasses.ts'
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
    base: 'inline-flex justify-center items-center border-0',
    success: 'bg-green-300 text-green-500 dark:bg-green-900 dark:text-green-500',
    info: 'bg-blue-500 text-blue-800 dark:bg-blue-950 dark:text-blue-800',
    tertiary: 'bg-blue-200 text-stone-200 dark:bg-gray-700  dark:text-neutral-500',
    warning: 'bg-yellow-50 text-yellow-600 dark:bg-yellow-900 dark:text-yellow-600',
    danger: 'bg-pink-100 text-red-500 dark:bg-red-900 dark:text-red-500',
    neutral: 'text-gray-100 bg-neutral-50 dark:text-neutral-400 dark:bg-gray-500',
    highlight: 'border-2 border-white bg-pink-500 text-white dark:border-gray-500',
    custom: 'badge-custom',
  })

  initializeAlertClasses({
    base: 'grid gap-1.5 text-center md:text-start text-sm items-start justify-center md:justify-start grid-flow-row md:grid-flow-col md:grid-cols-[auto_minmax(auto,_1fr)] w-full md:w-auto',
    success: 'bg-green-300 dark:bg-green-900 text-green-500',
    info: 'bg-blue-500 dark:bg-blue-950 text-blue-800',
    warning: 'bg-yellow-50 dark:bg-yellow-900 text-yellow-600',
    danger: 'bg-pink-100 dark:bg-red-900 text-red-500',
    dismissButton:
      'outline-transparent focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 rounded-sm',
  })

  initializeAvatarClasses({
    base: 'border border-neutral-100 dark:border-gray-900 text-black',
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
    base: 'cursor-pointer no-underline hover:underline text-blue-800 hover:text-blue-850 hover:dark:text-blue-600 focus-visible:rounded-xs focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800',
    internal: 'hover:no-underline!',
  })

  initializeNotificationClasses({
    base: 'rounded-lg p-2 border-transparent focus-visible-app-default',
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
      base: 'gap-1',
      button: 'w-4',
      autoButton: 'h-4 bg-blue-200 text-black dark:bg-gray-700 dark:text-white',
      autoButtonIcon: '',
    },
  })

  initializeEditorLinkFormClasses({
    button: {
      danger:
        'bg-pink-100 hover:bg-pink-100 dark:bg-red-900 dark:hover:bg-red-900 text-red-500 px-4 py-2.5 rounded-xl focus-visible-app-default hover:outline-1 dark:hover:outline-blue-900 hover:outline-offset-1 hover:outline-blue-600',
      secondary:
        'bg-transparent hover:bg-transparent text-blue-800 px-4 py-2.5 rounded-xl focus-visible-app-default hover:outline-1 hover:outline-offset-1 dark:hover:outline-blue-900 hover:outline-blue-600',
      primary:
        'bg-blue-800 hover:bg-blue-800 text-white px-4 py-2.5 rounded-xl focus-visible-app-default hover:outline-1 hover:outline-offset-1 dark:hover:outline-blue-900 hover:outline-blue-600',
    },
    form: 'rounded-xl min-w-md space-y-4 px-2.5 py-2.5 pb-4 border border-neutral-100 dark:border-gray-900 dark:bg-gray-500 bg-neutral-50',
    buttonContainer: 'flex gap-4',
  })

  initializeAiAssistantTextToolsClasses({
    popover: {
      base: 'min-w-[13.5rem] rounded-xl overflow-hidden',
      item: '',
      button:
        'text-sm outline-none p-3 text-left active:text-white active:bg-blue-800 dark:active:bg-blue-800 dark:hover:text-white hover:text-black inline-block w-full dark:text-neutral-400 focus-visible:bg-blue-800 focus-visible:text-white hover:bg-blue-600 dark:hover:bg-blue-900 text-gray-100',
    },
  })

  initializeFilePreviewClasses({
    base: 'dark:text-white text-black text-sm leading-snug',
    wrapper: 'p-2.5',
    preview:
      'hover:outline hover:outline-1 hover:outline-offset-1 hover:outline-blue-600 focus:outline-hidden focus:outline-0 focus:outline-offset-0 focus:hover:outline-1 focus:hover:outline-offset-1 focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 dark:hover:outline-blue-900',
    link: 'hover:rounded-xs hover:no-underline! hover:outline-1 hover:outline-offset-1 hover:outline-blue-600 dark:hover:outline-blue-900',
    size: 'dark:text-neutral-500 text-stone-400 text-xs leading-snug',
    icon: 'dark:text-neutral-500 text-stone-400',
  })

  initializeAiAssistantTextToolsLoadingBannerClasses({
    icon: 'text-blue-800',
    label: 'text-black! dark:text-white!',
    button: 'text-blue-800',
  })

  initializeProgressBarClasses('focus-visible-app-default')
}
