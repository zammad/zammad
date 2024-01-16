// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  NavigationGuard,
  RouteLocationNormalized,
  NavigationGuardNext,
} from 'vue-router'
import log from '#shared/utils/log.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

const systemSetupInfo: NavigationGuard = (
  to: RouteLocationNormalized,
  from: RouteLocationNormalized,
  next: NavigationGuardNext,
) => {
  const application = useApplicationStore()

  if (
    application.config.system_init_done ||
    (to.fullPath && to.fullPath.startsWith('/guided-setup'))
  ) {
    next()
    return
  }

  if (application.config.import_mode) {
    log.debug(`Route guard for '${to.path}': system setup - import mode.`)
    next({ path: '/guided-setup/import', replace: true }) // TODO: add real route when exists
    return
  }

  log.debug(`Route guard for '${to.path}': system setup - not initialized.`)
  next({ path: '/guided-setup', replace: true })
}

export default systemSetupInfo
