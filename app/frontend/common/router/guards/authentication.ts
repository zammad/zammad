// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import useApplicationLoadedStore from '@common/stores/application/loaded'
import useAuthenticatedStore from '@common/stores/authenticated'
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
    next('login')
  } else if (to.name === 'Login' && authenticated.value) {
    next('/')
  } else {
    next()
  }
}

const authenticationGuard: NavigationGuard = (to, from, next) => {
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
