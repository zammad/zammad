import { useSessionIdQuery } from '@common/graphql/api'
import { defineStore } from 'pinia'
import { provideApolloClient } from '@vue/apollo-composable'
import apolloClient from '@common/server/apollo/client'
import { QueryHandler } from '@common/server/apollo/handler'
import { DefaultStore } from '@common/types/store'

provideApolloClient(apolloClient) // TODO needed -> move?

const useSessionIdStore = defineStore('sessionId', {
  state: (): DefaultStore<Maybe<string>> => {
    return {
      value: null,
    }
  },
  actions: {
    async checkSession(): Promise<string | null> {
      const sessionIdQuery = new QueryHandler(
        useSessionIdQuery,
        {},
        {
          // Always fetch the current session information from the server,
          // because otherwise we have not the correct authenticated state.
          fetchPolicy: 'network-only',
        },
        {
          errorShowNotification: false,
          errorLogLevel: 'silent',
        },
      )

      const result = await sessionIdQuery.loadedResult()

      // Refresh the current sessionId state.
      this.value = result?.sessionId || null

      return this.value
    },
  },
})

export default useSessionIdStore
