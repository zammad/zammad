// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { watch } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import log from '#shared/utils/log.ts'

import type { WatchStopHandle } from 'vue'
import type {
  NavigationGuard,
  RouteLocationNormalized,
  NavigationGuardNext,
} from 'vue-router'

const checkAuthenticated = (
  to: RouteLocationNormalized,
  next: NavigationGuardNext,
) => {
  const { authenticated } = useAuthenticationStore()

  if (to.name !== 'Login' && to.meta.requiresAuth && !authenticated) {
    log.debug(
      `Route guard for '${to.path}': authentication - forbidden - unauthenticated.`,
    )

    if (to.fullPath !== '/') {
      next({ path: '/login', query: { redirect: to.fullPath } })
    } else {
      next({ path: '/login' })
    }
  } else if (to.meta.redirectToDefaultRoute && authenticated) {
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
  let unwatch: WatchStopHandle | undefined
  const application = useApplicationStore()

  if (application.loading) {
    unwatch = watch(
      () => application.loaded,
      () => {
        checkAuthenticated(to, next)
      },
    )
  } else {
    if (unwatch) {
      unwatch()
      unwatch = undefined
    }
    checkAuthenticated(to, next)
  }
}

export default authenticationGuard
