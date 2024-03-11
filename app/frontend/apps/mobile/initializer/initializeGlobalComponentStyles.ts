// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { initializeLinkClasses } from '#shared/initializer/initializeLinkClasses.ts'
import { initializeNotificationClasses } from '#shared/initializer/initializeNotificationClasses.ts'
import { initializeAlertClasses } from '#shared/initializer/initializeAlertClasses.ts'

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
    link: 'hover:underline',
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
}
