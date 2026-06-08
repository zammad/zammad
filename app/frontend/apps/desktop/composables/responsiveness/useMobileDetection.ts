// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { watch } from 'vue'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'

import { useAppBreakpoints } from './useAppBreakpoints.ts'

export const useMobileDetection = () => {
  const { isSmallestScreen } = useAppBreakpoints()

  const activeNotificationId = 'mobile-screen-size'
  // Once per session we show the notification
  let hasShownNotification = false

  const { notify, removeNotification } = useNotifications()

  watch(
    isSmallestScreen,
    (hasMobileScreenSize) => {
      if (!hasMobileScreenSize) return removeNotification(activeNotificationId)
      if (hasShownNotification) return

      notify({
        id: 'mobile-screen-size',
        type: NotificationTypes.Warn,
        message: __(
          "This screen size isn't fully supported for the desktop layout. For the best experience, switch to the mobile layout.",
        ),
        persistent: true,
      })

      hasShownNotification = true
    },
    { immediate: true },
  )
}
