// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { ErrorStatusCodes } from '#shared/types/error.ts'
import log from '#shared/utils/log.ts'

import { errorOptions } from '../../error.ts'

import type { NavigationGuard, RouteLocationNormalized } from 'vue-router'

const permissionGuard: NavigationGuard = (to: RouteLocationNormalized) => {
  // Authentication is handled by a separate guard; skip access checks for guests.
  if (!useAuthenticationStore().authenticated) {
    log.debug(`Route guard for '${to.path}': permission - skip.`)
    return true
  }

  const hasRequiredPermission =
    !to.meta.requiredPermission || useSessionStore().hasPermission(to.meta.requiredPermission)

  // Dynamic access gate (e.g. feature flags / config settings) on top of the permission.
  const canAccess = to.meta.canAccess?.() ?? true

  if (hasRequiredPermission && canAccess) {
    log.debug(`Route guard for '${to.path}': permission - allowed.`)
    return true
  }

  log.debug(`Route guard for '${to.path}': permission - forbidden.`)

  errorOptions.value = {
    title: __('Forbidden'),
    message: __("You don't have the necessary permissions to access this page."),
    statusCode: ErrorStatusCodes.Forbidden,
    route: to.fullPath,
  }

  return {
    name: 'Error',
    query: {
      redirect: '1',
    },
    replace: true,
  }
}

export default permissionGuard
