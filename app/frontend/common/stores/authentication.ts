// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { MutationHandler } from '@common/server/apollo/handler'
import { defineStore } from 'pinia'
import { useLoginMutation, useLogoutMutation } from '@common/graphql/api'
import useSessionStore from '@common/stores/session'
import { clearApolloClientStore } from '@common/server/apollo/client'
import useApplicationStore from '@common/stores/application'
import { ref } from 'vue'

const useAuthenticationStore = defineStore(
  'authentication',
  () => {
    const authenticated = ref(false)

    const clearAuthentication = async (): Promise<void> => {
      await clearApolloClientStore

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
