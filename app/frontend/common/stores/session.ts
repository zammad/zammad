// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { useCurrentUserQuery, useSessionIdQuery } from '@common/graphql/api'
import { QueryHandler } from '@common/server/apollo/handler'
import type { UserData } from '@common/types/store'
import useLocaleStore from '@common/stores/locale'
import hasPermission from '@common/permissions/hasPermission'
import type {
  CurrentUserQuery,
  CurrentUserQueryVariables,
  SessionIdQuery,
  SessionIdQueryVariables,
} from '@common/graphql/types'
import testFlags from '@common/utils/testFlags'
import { ref } from 'vue'

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

let currentUserQuery: QueryHandler<CurrentUserQuery, CurrentUserQueryVariables>

const getCurrentUserQuery = () => {
  if (currentUserQuery) return currentUserQuery

  currentUserQuery = new QueryHandler(
    useCurrentUserQuery({ fetchPolicy: 'no-cache' }),
  )

  return currentUserQuery
}

const useSessionStore = defineStore('session', () => {
  const id = ref<Maybe<string>>(null)

  const checkSession = async (): Promise<string | null> => {
    const sessionIdQuery = getSessionIdQuery()

    const result = await sessionIdQuery.loadedResult(true)

    // Refresh the current sessionId state.
    id.value = result?.sessionId || null

    return id.value
  }

  const user = ref<Maybe<UserData>>(null)

  const getCurrentUser = async (): Promise<Maybe<UserData>> => {
    const currentUserQuery = getCurrentUserQuery()

    const result = await currentUserQuery.loadedResult(true)
    user.value = result?.currentUser || null

    // Check if the locale is different, then a update is needed.
    const locale = useLocaleStore()
    const userLocale = user.value?.preferences?.locale

    if (
      userLocale &&
      (userLocale !== locale.localeData || !locale.localeData)
    ) {
      await locale.updateLocale(userLocale)
    }

    if (user.value) {
      testFlags.set('useSessionUserStore.getCurrentUser.loaded')
    }

    return user.value
  }

  const userHasPermission = (requiredPermission: Array<string>): boolean => {
    return hasPermission(
      requiredPermission,
      user.value?.permissions?.names || [],
    )
  }

  return {
    id,
    checkSession,
    user,
    getCurrentUser,
    hasPermission: userHasPermission,
  }
})

export default useSessionStore
