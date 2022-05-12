// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'
import { defineStore } from 'pinia'
import { MutationHandler } from '@shared/server/apollo/handler'
import { useLoginMutation } from '@shared/graphql/mutations/login.api'
import { useLogoutMutation } from '@shared/graphql/mutations/logout.api'
import { clearApolloClientStore } from '@shared/server/apollo/client'
import useSessionStore from './session'
import useApplicationStore from './application'

const useAuthenticationStore = defineStore(
  'authentication',
  () => {
    const authenticated = ref(false)

    const clearAuthentication = async (): Promise<void> => {
      await clearApolloClientStore()

      const session = useSessionStore()
      session.id = null
      session.user = null
      authenticated.value = false

      // Refresh the config after logout, to have only the non authenticated version.
      await useApplicationStore().resetAndGetConfig()

      // TODO... check for other things which must be removed/cleared during a logout.
    }

    const refreshAfterAuthentication = async (): Promise<void> => {
      await Promise.all([
        useApplicationStore().getConfig(),
        useSessionStore().getCurrentUser(),
      ])
    }

    const logout = async (): Promise<void> => {
      const logoutMutation = new MutationHandler(useLogoutMutation())

      const result = await logoutMutation.send()

      if (result?.logout?.success) {
        await clearAuthentication()
      }
    }

    const login = async (login: string, password: string): Promise<void> => {
      const loginMutation = new MutationHandler(
        useLoginMutation({
          variables: {
            login,
            password,
            fingerprint: '123456', // TODO ...use the real value
          },
        }),
      )

      const result = await loginMutation.send()

      const newSessionId = result?.login?.sessionId || null
      if (newSessionId) {
        const session = useSessionStore()
        session.id = newSessionId
        authenticated.value = true
      }

      await refreshAfterAuthentication()

      return Promise.resolve()
    }

    return {
      authenticated,
      clearAuthentication,
      logout,
      login,
      refreshAfterAuthentication,
    }
  },
  {
    shareState: {
      enabled: true,
    },
  },
)

export default useAuthenticationStore
