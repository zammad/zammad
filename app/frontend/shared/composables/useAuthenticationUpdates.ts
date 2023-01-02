// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useApplicationStore } from '@shared/stores/application'
import { useAuthenticationStore } from '@shared/stores/authentication'
import { useSessionStore } from '@shared/stores/session'

// Add a watcher for authenticated changes (e.g. login/logout in a other browser tab).
const useAuthenticationChanges = () => {
  const session = useSessionStore()
  const authentication = useAuthenticationStore()
  const application = useApplicationStore()

  const router = useRouter()
  const route = useRoute()

  authentication.$subscribe(async (mutation, state) => {
    if (state.authenticated && !session.id) {
      session.checkSession().then(async (sessionId) => {
        if (sessionId) {
          await authentication.refreshAfterAuthentication()
        }

        if (route.name === 'Login') {
          router.replace('/')
        }
      })
    } else if (!state.authenticated && session.id) {
      await authentication.clearAuthentication()
      router.replace('/login')
    }
  })

  watch(
    () => application.config.maintenance_mode,
    async (newValue, oldValue) => {
      if (
        !oldValue &&
        newValue &&
        authentication.authenticated &&
        !session.hasPermission(['admin.maintenance', 'maintenance'])
      ) {
        await authentication.logout()
        router.replace('/login')
      }
    },
  )
}

export default useAuthenticationChanges
