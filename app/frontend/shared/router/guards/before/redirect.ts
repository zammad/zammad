// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { getCurrentRouter } from '#shared/router/router.ts'
import log from '#shared/utils/log.ts'

import type { NavigationGuard, RouteLocationNormalized } from 'vue-router'

const redirectGuard: NavigationGuard = (to: RouteLocationNormalized) => {
  // Prevent redirection loops
  if (to.redirectedFrom) {
    log.debug(`Route guard for '${to.fullPath}': redirect - skipping.`)

    return true
  }

  const location = to.hash && to.hash.slice(1)
  if (!location) return true

  // Resolve the route using the global router instance.
  //   This requires the app to expose it via the `window` global during router initialization.
  //   Make sure that each route has a suitable alias defined that should correspond to the old path.
  const route = getCurrentRouter().resolve(location)

  // Supports `Error` route name only for now.
  const path = route.name === 'Error' ? '/' : `/${location}`

  log.debug(`Route guard for '${to.fullPath}': redirect - '${path}'.`)

  return {
    path,
    replace: true,
  }
}

export default redirectGuard
