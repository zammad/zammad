// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '#shared/stores/application.ts'
import log from '#shared/utils/log.ts'

import type { NavigationGuard, RouteLocationNormalized } from 'vue-router'

const systemSetupInfo: NavigationGuard = (to: RouteLocationNormalized) => {
  const application = useApplicationStore()

  if (
    application.config.system_init_done ||
    (to.fullPath && to.fullPath.startsWith('/guided-setup'))
  ) {
    return true
  }

  if (application.config.import_mode) {
    log.debug(`Route guard for '${to.path}': system setup - import mode.`)
    return {
      path: `/guided-setup/import/${application.config.import_backend}/status`,
      replace: true,
    }
  }

  log.debug(`Route guard for '${to.path}': system setup - not initialized.`)
  return { path: '/guided-setup', replace: true }
}

export default systemSetupInfo
