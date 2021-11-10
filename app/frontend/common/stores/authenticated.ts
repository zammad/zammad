// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { MutationHandler } from '@common/server/apollo/handler'
import { defineStore } from 'pinia'
import { useLoginMutation, useLogoutMutation } from '@common/graphql/api'
import { DefaultStore } from '@common/types/store'
import useSessionIdStore from '@common/stores/session/id'
import apolloClient from '@common/server/apollo/client'

// TODO add this as a persistent state
const useAuthenticatedStore = defineStore('authenticated', {
  state: (): DefaultStore<boolean> => {
    return {
      value: false,
    }
  },
  actions: {
    async logout(): Promise<void> {
      const logoutMutation = new MutationHandler(useLogoutMutation)

      const result = await logoutMutation.loadedResult()

      if (result?.logout?.success) {
        this.value = false

        const sessionId = useSessionIdStore()
        sessionId.value = null

        apolloClient.clearStore()

        // TODO... check for other things which must be removed/cleared during a logout.
      }
    },

    async login(login: string, password: string): Promise<void> {
      const loginMutation = new MutationHandler(
        useLoginMutation,
        {
          login,
          password,
          fingerprint: '123456', // TODO ...use the real value
        },
        {},
        {
          directSendMutation: true,
        },
      )

      const result = await loginMutation.loadedResult()

      const newSessionId = result?.login?.sessionId || null

      if (newSessionId) {
        this.value = true

        const sessionId = useSessionIdStore()
        sessionId.value = newSessionId
      }
    },
  },
})

export default useAuthenticatedStore
