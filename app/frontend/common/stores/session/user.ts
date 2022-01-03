// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { useCurrentUserQuery } from '@common/graphql/api'
import { defineStore } from 'pinia'
import { QueryHandler } from '@common/server/apollo/handler'
import type { SingleValueStore, UserData } from '@common/types/store'
import useLocaleStore from '@common/stores/locale'
import hasPermission from '@common/permissions/hasPermission'
import type {
  CurrentUserQuery,
  CurrentUserQueryVariables,
} from '@common/graphql/types'

let currentUserQuery: QueryHandler<CurrentUserQuery, CurrentUserQueryVariables>

const getCurrentUserQuery = () => {
  if (currentUserQuery) return currentUserQuery

  currentUserQuery = new QueryHandler(
    useCurrentUserQuery({ fetchPolicy: 'no-cache' }),
  )

  return currentUserQuery
}

const useSessionUserStore = defineStore('sessionUser', {
  state: (): SingleValueStore<Maybe<UserData>> => {
    return {
      value: null,
    }
  },
  actions: {
    async getCurrentUser(): Promise<UserData> {
      const currentUserQuery = getCurrentUserQuery()

      const result = await currentUserQuery.loadedResult(true)
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
