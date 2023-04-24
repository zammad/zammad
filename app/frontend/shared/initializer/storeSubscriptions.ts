// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { watch } from 'vue'
import consumer from '#shared/server/action_cable/consumer.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

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
          consumer.connection.reopen()
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
