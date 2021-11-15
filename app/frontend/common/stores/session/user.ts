// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { useCurrentUserQuery } from '@common/graphql/api'
import { defineStore } from 'pinia'
import { QueryHandler } from '@common/server/apollo/handler'
import { SingleValueStore, UserData } from '@common/types/store'

const useSessionUserStore = defineStore('sessionUser', {
  state: (): SingleValueStore<Maybe<UserData>> => {
    return {
      value: null,
    }
  },
  actions: {
    async getCurrentUser(refetchQuery = false): Promise<UserData> {
      const currentUserQuery = new QueryHandler(useCurrentUserQuery())

      // Trigger query refetch in some situtations, to skip the cache.
      if (refetchQuery) {
        currentUserQuery.refetch()
      }

      const result = await currentUserQuery.onLoaded()

      this.value = result?.currentUser || null

      return this.value
    },
  },
})

export default useSessionUserStore
