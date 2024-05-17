// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { watch } from 'vue'

import { triggerWebSocketReconnect } from '#shared/server/connection.ts'
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
}
