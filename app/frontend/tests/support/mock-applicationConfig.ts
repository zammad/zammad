// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '#shared/stores/application.ts'
import type { ConfigList } from '#shared/types/store.ts'
import { initializePiniaStore } from './components/renderComponent.ts'

export const mockApplicationConfig = (config: ConfigList) => {
  initializePiniaStore()

  const application = useApplicationStore()

  application.config = config
}
