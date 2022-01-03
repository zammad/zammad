// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type {
  NavigationGuard,
  RouteLocationNormalized,
  NavigationGuardNext,
} from 'vue-router'
import useAuthenticationStore from '@common/stores/authenticated'
import useSessionUserStore from '@common/stores/session/user'
import { ErrorStatusCodes } from '@common/types/error'
import log from '@common/utils/log'

const permissionGuard: NavigationGuard = (
  to: RouteLocationNormalized,
  from: RouteLocationNormalized,
  next: NavigationGuardNext,
) => {
  // When no required permission are defined or no authentication
  // exists, the permission check can be skipped.
  if (!to.meta.requiredPermission || !useAuthenticationStore().value) {
    log.debug(`Route guard for '${to.path}': permission - skip.`)
    next()
    return
  }

  // TODO check the permission for the current user...
  const hasPermission = useSessionUserStore().hasPermission(
    to.meta.requiredPermission,
  )
  if (!hasPermission) {
    log.debug(`Route guard for '${to.path}': permission - forbidden.`)

    next({
      name: 'Error',
      params: {
        title: __('Forbidden'),
        message: __(
          "You don't have the necessary permissions to access this page.",
        ),
        statusCode: ErrorStatusCodes.Forbidden,
        route: to.fullPath,
      },
      replace: true,
    })
    return
  }

  log.debug(`Route guard for '${to.path}': permission - allowed.`)
  next()
}

export default permissionGuard
