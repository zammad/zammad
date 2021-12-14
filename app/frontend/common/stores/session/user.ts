// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { useCurrentUserQuery } from '@common/graphql/api'
import { defineStore } from 'pinia'
import { QueryHandler } from '@common/server/apollo/handler'
import { SingleValueStore, UserData } from '@common/types/store'
import useLocaleStore from '@common/stores/locale'
import hasPermission from '@common/permissions/hasPermission'

const useSessionUserStore = defineStore('sessionUser', {
  state: (): SingleValueStore<Maybe<UserData>> => {
    return {
      value: null,
    }
  },
  actions: {
    async getCurrentUser(refetchQuery = false): Promise<UserData> {
      const currentUserQuery = new QueryHandler(useCurrentUserQuery())

      // Trigger query refetch in some situtations or if already some data exists,
      // to skip the cache.
      if (refetchQuery || currentUserQuery.result().value?.currentUser) {
        currentUserQuery.refetch()
      }

      const result = await currentUserQuery.onLoaded()
      this.value = result?.currentUser || null

      // Check if the locale is different, then a update is needed.
      const locale = useLocaleStore()
      const userLocale = this.value?.preferences?.locale

      if (userLocale && (userLocale !== locale.value || !locale.value)) {
        await locale.updateLocale(userLocale)
      }

      return this.value
    },

    hasPermission(requiredPermission: Array<string>): boolean {
      return hasPermission(
        requiredPermission,
        this.value?.permissions?.names || [],
      )
    },
  },
})

export default useSessionUserStore
