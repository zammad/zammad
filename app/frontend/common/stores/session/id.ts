// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { useSessionIdQuery } from '@common/graphql/api'
import { defineStore } from 'pinia'
import { QueryHandler } from '@common/server/apollo/handler'
import { SingleValueStore } from '@common/types/store'

const useSessionIdStore = defineStore('sessionId', {
  state: (): SingleValueStore<Maybe<string>> => {
    return {
      value: null,
    }
  },
  actions: {
    async checkSession(): Promise<string | null> {
      const sessionIdQuery = new QueryHandler(
        useSessionIdQuery({
          fetchPolicy: 'no-cache',
          context: {
            error: {
              logLevel: 'silent',
            },
          },
        }),
        {
          errorShowNotification: false,
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
