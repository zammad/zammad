// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'
import { watch } from 'vue'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'

import { useAppBreakpoints } from './useAppBreakpoints.ts'

export const useMobileDetection = () => {
  const { isSmallestScreen } = useAppBreakpoints()

  const activeNotificationId = 'mobile-screen-size'

  const hasShownNotification = useLocalStorage('hasShownWarningNotificationForSmallScreen', false)

  const { notify, removeNotification } = useNotifications()

  let hasSeenInSession = false

  watch(
    isSmallestScreen,
    (hasMobileScreenSize) => {
      if (!hasMobileScreenSize) return removeNotification(activeNotificationId)
      if (hasShownNotification.value || hasSeenInSession) return

      notify({
        id: 'mobile-screen-size',
        type: NotificationTypes.Warn,
        message: __(
          'The desktop layout works best on wider screens. Current screen width may not display all desktop content optimally.',
        ),
        persistent: true,
        closeCallback() {
          hasShownNotification.value = true
        },
      })

      hasSeenInSession = true
    },
    { immediate: true },
  )
}
