// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { useSessionIdQuery } from '@common/graphql/api'
import { defineStore } from 'pinia'
import { QueryHandler } from '@common/server/apollo/handler'
import type { SingleValueStore } from '@common/types/store'
import type {
  SessionIdQuery,
  SessionIdQueryVariables,
} from '@common/graphql/types'

let sessionIdQuery: QueryHandler<SessionIdQuery, SessionIdQueryVariables>

const getSessionIdQuery = () => {
  if (sessionIdQuery) return sessionIdQuery

  sessionIdQuery = new QueryHandler(
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

  return sessionIdQuery
}

const useSessionIdStore = defineStore('sessionId', {
  state: (): SingleValueStore<Maybe<string>> => {
    return {
      value: null,
    }
  },
  actions: {
    async checkSession(): Promise<string | null> {
      const sessionIdQuery = getSessionIdQuery()

      const result = await sessionIdQuery.loadedResult(true)

      // Refresh the current sessionId state.
      this.value = result?.sessionId || null

      return this.value
    },
  },
})

export default useSessionIdStore
