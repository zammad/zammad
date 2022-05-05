// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import useLocaleStore from '@shared/stores/locale'
import useSessionStore from '@shared/stores/session'
import useApplicationStore from '@shared/stores/application'
import consumer from '@shared/server/action_cable/consumer'
import { watch } from 'vue'

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
        (newValue) => {
          if (!newValue) {
            locale.updateLocale()
          }
        },
      )
    },
  )
}
