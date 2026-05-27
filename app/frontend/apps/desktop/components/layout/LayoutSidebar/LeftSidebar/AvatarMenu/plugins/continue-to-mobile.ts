// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isMobile } from '#shared/utils/browser.ts'

import {
  MOBILE_SLUG,
  useMobileNavigation,
} from '#desktop/composables/responsiveness/useMobileNavigation.ts'

import type { AvatarMenuPlugin } from './index.ts'

export default <AvatarMenuPlugin>{
  key: 'continue-to-mobile',
  label: __('Continue to mobile'),
  icon: 'mobile',
  link: MOBILE_SLUG,
  onClick: () => {
    const { clearForceDesktopApp } = useMobileNavigation()

    clearForceDesktopApp()
  },
  show: () => {
    const { forceDesktopApp } = useMobileNavigation()

    return forceDesktopApp.value || isMobile
  },
  order: 150,
}
