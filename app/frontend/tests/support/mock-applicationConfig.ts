// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import useApplicationStore from '@shared/stores/application'
import type { ConfigList } from '@shared/types/store'
import { initializeStore } from './components/renderComponent'

export const mockApplicationConfig = (config: ConfigList) => {
  initializeStore()

  const application = useApplicationStore()

  application.config = config
}
