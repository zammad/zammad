// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import useApplicationLoadedStore from '@common/stores/application/loaded'
import useAuthenticatedStore from '@common/stores/authenticated'
import log from '@common/utils/log'
import {
  NavigationGuard,
  RouteLocationNormalized,
  NavigationGuardNext,
} from 'vue-router'

const checkAuthenticated = (
  to: RouteLocationNormalized,
  next: NavigationGuardNext,
) => {
  const authenticated = useAuthenticatedStore()

  if (to.name !== 'Login' && to.meta.requiresAuth && !authenticated.value) {
    log.debug(
      `Route guard for '${to.path}': authentication - forbidden - unauthenticated.`,
    )
    next('login')
  } else if (to.name === 'Login' && authenticated.value) {
    // Use the default route here.
    log.debug(
      `Route guard for '${to.path}': authentication - forbidden - authenticated.`,
    )
    next('/')
  } else {
    log.debug(
      `Route guard for '${to.path}': authentication - allowed - public.`,
    )
    next()
  }
}

const authenticationGuard: NavigationGuard = (
  to: RouteLocationNormalized,
  from: RouteLocationNormalized,
  next: NavigationGuardNext,
) => {
  let unsubscribe: (() => void) | undefined
  const loaded = useApplicationLoadedStore()

  if (loaded.loading) {
    unsubscribe = loaded.$subscribe(() => {
      checkAuthenticated(to, next)
    })
  } else {
    if (unsubscribe) {
      unsubscribe()
      unsubscribe = undefined
    }
    checkAuthenticated(to, next)
  }
}

export default authenticationGuard
