// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useSystemSetupInfoStore } from '#desktop/pages/guided-setup/stores/systemSetupInfo.ts'

export const systemSetupBeforeRouteEnterGuard = () => {
  const { systemSetupDone } = useSystemSetupInfoStore()

  if (systemSetupDone) {
    return '/'
  }

  return true
}
