// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '#shared/stores/application.ts'
import type { ConfigList } from '#shared/types/store.ts'

import { initializePiniaStore } from './components/renderComponent.ts'

export const mockApplicationConfig = (config: Partial<ConfigList>) => {
  initializePiniaStore()

  const application = useApplicationStore()

  application.config = {
    ...application.config,
    ...config,
  } as ConfigList
}
