// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { ErrorStatusCodes } from '#shared/types/error.ts'
import log from '#shared/utils/log.ts'

import { errorOptions } from '../../error.ts'

import type { NavigationGuard, RouteLocationNormalized } from 'vue-router'

const permissionGuard: NavigationGuard = (to: RouteLocationNormalized) => {
  // When no required permission are defined or no authentication
  // exists, the permission check can be skipped.
  if (!to.meta.requiredPermission || !useAuthenticationStore().authenticated) {
    log.debug(`Route guard for '${to.path}': permission - skip.`)
    return true
  }

  // check the permission for the current user...
  const hasPermission = useSessionStore().hasPermission(to.meta.requiredPermission)
  if (!hasPermission) {
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

  log.debug(`Route guard for '${to.path}': permission - allowed.`)
  return true
}

export default permissionGuard
