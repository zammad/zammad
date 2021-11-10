// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { useCurrentUserQuery } from '@common/graphql/api'
import { defineStore } from 'pinia'
import { QueryHandler } from '@common/server/apollo/handler'
import { DefaultStore, UserData } from '@common/types/store'

const useSessionUserStore = defineStore('sessionUser', {
  state: (): DefaultStore<Maybe<UserData>> => {
    return {
      value: null,
    }
  },
  actions: {
    async getCurrentUser(): Promise<UserData> {
      const currentUserQuery = new QueryHandler(useCurrentUserQuery)

      const result = await currentUserQuery.onLoaded()

      this.value = result?.currentUser || null

      return this.value
    },
  },
})

export default useSessionUserStore
