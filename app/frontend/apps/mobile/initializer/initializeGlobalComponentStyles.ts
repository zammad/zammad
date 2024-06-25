// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { initializeEditorColorMenuClasses } from '#shared/components/Form/fields/FieldEditor/FieldEditorColorMenu/initializeEditorColorMenu.ts'
import { initializeAlertClasses } from '#shared/initializer/initializeAlertClasses.ts'
import { initializeAvatarClasses } from '#shared/initializer/initializeAvatarClasses.ts'
import { initializeFilePreviewClasses } from '#shared/initializer/initializeFilePreviewClasses.ts'
import { initializeLinkClasses } from '#shared/initializer/initializeLinkClasses.ts'
import { initializeNotificationClasses } from '#shared/initializer/initializeNotificationClasses.ts'
import { initializeOrganizationAvatarClasses } from '#shared/initializer/initializeOrganizationAvatarClasses.ts'
import { initializePopoverClasses } from '#shared/initializer/initializePopover.ts'
import { initializeUserAvatarClasses } from '#shared/initializer/initializeUserAvatarClasses.ts'

export const initializeGlobalComponentStyles = () => {
  initializeLinkClasses({
    base: '',
  })

  initializeAlertClasses({
    base: 'grid w-full content-start items-center justify-items-center text-center grid-flow-col grid-cols-[auto_minmax(auto,1fr)] justify-items-start text-start border w-auto text-sm',
    success: 'alert-success bg-green text-white',
    info: 'alert-info bg-white text-black',
    warning: 'alert-warning bg-yellow text-black',
    danger: 'alert-error bg-red/60 text-white',
  })

  initializeAvatarClasses({
    base: 'text-black',
    vipUser: 'text-yellow',
    vipOrganization: 'text-gray-100',
  })

  initializeUserAvatarClasses({
    backgroundColors: [
      'bg-gray',
      'bg-red-bright',
      'bg-yellow',
      'bg-blue',
      'bg-green',
      'bg-pink',
      'bg-orange',
    ],
  })

  initializeOrganizationAvatarClasses({
    base: 'bg-gray-200 text-black',
    inactive: 'opacity-30',
  })

  initializeNotificationClasses({
    base: 'rounded px-4 py-2',
    baseContainer: 'ltr:right-0 rtl:left-0',
    error: 'bg-red/60 text-white',
    info: 'bg-white text-black',
    message: 'ltr:ml-2 rtl:mr-2',
    success: 'bg-green text-white',
    warn: 'bg-yellow text-black',
  })

  initializePopoverClasses({
    base: 'min-h-9 rounded-xl max-w-[calc(100vw-8px)] text-white top-0 border border-gray-500 bg-gray-400 antialiased rtl:right-1/2 ltr:left-1/2 rtl:translate-x-1/2 ltr:-translate-x-1/2',
    arrow: 'hidden',
  })

  initializeEditorColorMenuClasses({
    colorSchemeList: {
      base: 'border-b  pb-1',
      button: 'p-4',
    },
  })

  //   Initialize editor classes
  // :TODO Sub Folder

  initializeFilePreviewClasses({
    base: 'leading-4',
    wrapper:
      'focus-within:bg-blue-highlight mb-2 gap-2 rounded-2xl border p-3 outline-none last:mb-0 -:border-gray-300',
    preview: '',
    link: '',
    size: '-:text-white/80',
    icon: '-:border-gray-300',
  })
}
