// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'
import { readonly } from 'vue'

export const MOBILE_SLUG = '/mobile'

export const useMobileNavigation = () => {
  // Gets set in mobile app whenever the user click on "Continue to desktop"
  // It forces then the user to always redirect to desktop app
  // KEEP in mind it will always redirect to the DESKTOP APP
  const forceDesktopApp = useLocalStorage<boolean | undefined>('forceDesktopApp', undefined)

  // The prerequisite is that the user has been set in on mobile
  const clearForceDesktopApp = () => {
    if (forceDesktopApp.value === undefined) return

    forceDesktopApp.value = undefined
  }

  const continueToMobile = () => {
    window.location.href = MOBILE_SLUG
  }

  return {
    forceDesktopApp: readonly(forceDesktopApp),
    clearForceDesktopApp,
    continueToMobile,
  }
}
