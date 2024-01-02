// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { initializeLinkClasses } from '#shared/initializer/initializeLinkClasses.ts'
import { initializeNotificationClasses } from '#shared/initializer/initializeNotificationClasses.ts'

export const initializeGlobalComponentStyles = () => {
  initializeLinkClasses({
    base: '',
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
