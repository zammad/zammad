// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { watch } from 'vue'

import { triggerWebSocketReconnect } from '#shared/server/connection.ts'
import { useAiAssistantTextToolsStore } from '#shared/stores/aiAssistantTextTools.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import { useSessionStore } from '#shared/stores/session.ts'

export default function initializeStoreSubscriptions(): void {
  const session = useSessionStore()
  const locale = useLocaleStore()
  const application = useApplicationStore()

  watch(
    () => application.loaded,
    () => {
      watch(
        () => session.id,
        () => {
          // Reopen WS connection to reflect authentication state.
          triggerWebSocketReconnect()
        },
      )

      watch(
        () => session.user,
        (newValue, oldValue) => {
          if (
            !newValue ||
            (oldValue?.preferences?.locale &&
              locale.localeData &&
              newValue.preferences?.locale !== locale.localeData.locale)
          ) {
            locale.setLocale(newValue?.preferences?.locale)
          }
        },
      )
    },
  )

  // We dispose the ai assitant text tools store, when the feature will be disabled.
  // With this we removing the no longer needed subscription.
  watch(
    () => application.config.ai_assistance_text_tools,
    (newValue) => {
      if (!newValue) {
        useAiAssistantTextToolsStore().$dispose()
      }
    },
  )
}
