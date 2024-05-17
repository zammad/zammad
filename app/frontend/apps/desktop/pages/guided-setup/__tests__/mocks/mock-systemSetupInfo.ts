// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { initializePiniaStore } from '#tests/support/components/renderComponent.ts'

import { useSystemSetupInfoStore } from '../../stores/systemSetupInfo.ts'

import type { SystemSetupInfoStorage } from '../../types/setup-info.ts'

export const mockSystemSetupInfo = (
  systemSetupInfo: SystemSetupInfoStorage,
) => {
  initializePiniaStore()

  const systemSetupInfoStore = useSystemSetupInfoStore()
  systemSetupInfoStore.systemSetupInfo = systemSetupInfo
}
