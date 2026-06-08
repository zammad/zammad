// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { watch } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import log from '#shared/utils/log.ts'

import type { NavigationGuard, RouteLocationNormalized } from 'vue-router'

const checkAuthenticated = (to: RouteLocationNormalized) => {
  const { authenticated } = useAuthenticationStore()

  if (to.name !== 'Login' && to.meta.requiresAuth && !authenticated) {
    log.debug(`Route guard for '${to.path}': authentication - forbidden - unauthenticated.`)

    if (to.fullPath !== '/') {
      return { path: '/login', query: { redirect: to.fullPath } }
    } else {
      return { path: '/login' }
    }
  } else if (to.meta.redirectToDefaultRoute && authenticated) {
    // Use the default route here.
    log.debug(`Route guard for '${to.path}': authentication - forbidden - authenticated.`)
    return '/'
  } else {
    log.debug(`Route guard for '${to.path}': authentication - allowed - public.`)
    return true
  }
}

const authenticationGuard: NavigationGuard = (to: RouteLocationNormalized) => {
  const application = useApplicationStore()

  if (application.loading) {
    return new Promise((resolve) => {
      const unwatch = watch(
        () => application.loaded,
        () => {
          unwatch()
          resolve(checkAuthenticated(to))
        },
      )
    })
  } else {
    return checkAuthenticated(to)
  }
}

export default authenticationGuard
