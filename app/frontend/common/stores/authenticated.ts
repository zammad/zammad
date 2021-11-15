// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { MutationHandler } from '@common/server/apollo/handler'
import { defineStore } from 'pinia'
import { useLoginMutation, useLogoutMutation } from '@common/graphql/api'
import { SingleValueStore } from '@common/types/store'
import useSessionIdStore from '@common/stores/session/id'
import apolloClient from '@common/server/apollo/client'
import useApplicationConfigStore from '@common/stores/application/config'

// TODO add this as a persistent state
const useAuthenticatedStore = defineStore('authenticated', {
  state: (): SingleValueStore<boolean> => {
    return {
      value: false,
    }
  },
  actions: {
    async logout(): Promise<void> {
      const logoutMutation = new MutationHandler(useLogoutMutation())

      const result = await logoutMutation.send()

      if (result?.logout?.success) {
        this.value = false

        const sessionId = useSessionIdStore()
        sessionId.value = null

        await apolloClient.clearStore()

        // Refresh the config after logout, to have only the non authenticated version.
        const config = useApplicationConfigStore()
        await config.resetAndGetConfig()

        // TODO... check for other things which must be removed/cleared during a logout.
      }
    },

    async login(login: string, password: string): Promise<void> {
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
        this.value = true

        const sessionId = useSessionIdStore()
        sessionId.value = newSessionId

        const config = useApplicationConfigStore()
        await config.getConfig(true)
      }
    },
  },
})

export default useAuthenticatedStore
