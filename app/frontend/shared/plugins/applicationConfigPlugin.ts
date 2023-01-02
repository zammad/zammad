// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '@shared/stores/application'
import type { ConfigList } from '@shared/types/store'
import { storeToRefs } from 'pinia'
import type { App } from 'vue'
import { unref } from 'vue'

declare module '@vue/runtime-core' {
  export interface ComponentCustomProperties {
    $c: ConfigList
  }
}

const applicationConfigPlugin = (app: App) => {
  const application = useApplicationStore()
  const { config } = storeToRefs(application)

  Object.defineProperty(app.config.globalProperties, '$c', {
    enumerable: true,
    get: () => unref(config),
  })
}

export default applicationConfigPlugin
