// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'
import { defineStore } from 'pinia'
import { useSessionIdQuery } from '@shared/graphql/queries/sessionId.api'
import { useCurrentUserQuery } from '@shared/graphql/queries/currentUser.api'
import { QueryHandler } from '@shared/server/apollo/handler'
import type { UserData } from '@shared/types/store'
import hasPermission from '@shared/utils/hasPermission'
import type { RequiredPermission } from '@shared/types/permission'
import { CurrentUserUpdatesDocument } from '@shared/graphql/subscriptions/currentUserUpdates.api'
import type {
  CurrentUserQuery,
  CurrentUserQueryVariables,
  SessionIdQuery,
  SessionIdQueryVariables,
} from '@shared/graphql/types'
import testFlags from '@shared/utils/testFlags'
import useLocaleStore from './locale'

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

  currentUserQuery = new QueryHandler(useCurrentUserQuery())

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

  let currentUserSubscriptionInitialized = false
  let currentUserWatchOnResultInitialized = false
  const getCurrentUser = async (): Promise<Maybe<UserData>> => {
    if (currentUserQuery && !user.value) {
      currentUserQuery.start()
    }

    const query = getCurrentUserQuery()

    // Watch on result that also the subscription to more will update the user data.
    if (!currentUserWatchOnResultInitialized) {
      query.watchOnResult((result) => {
        user.value = result?.currentUser || null
      })
      currentUserWatchOnResultInitialized = true
    }

    await query.loadedResult(true)

    // Check if the locale is different, then a update is needed.
    const locale = useLocaleStore()
    const userLocale = user.value?.preferences?.locale as string

    if (
      userLocale &&
      (!locale.localeData || userLocale !== locale.localeData.locale)
    ) {
      await locale.setLocale(userLocale)
    }

    if (user.value) {
      testFlags.set('useSessionUserStore.getCurrentUser.loaded')

      query.watchOnResult((result) => {
        user.value = result?.currentUser || null
      })

      if (!currentUserSubscriptionInitialized) {
        query.operationResult.subscribeToMore({
          document: CurrentUserUpdatesDocument,
          variables: { userId: user.value.id },
        })

        currentUserSubscriptionInitialized = true
      }
    }

    return user.value
  }

  const resetCurrentSession = () => {
    if (currentUserQuery) currentUserQuery.stop()

    id.value = null
    user.value = null
  }

  const userHasPermission = (
    requiredPermission: RequiredPermission,
  ): boolean => {
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
    resetCurrentSession,
    hasPermission: userHasPermission,
  }
})

export default useSessionStore
