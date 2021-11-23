// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { App } from 'vue'
import { createPinia, Pinia } from 'pinia'
import PiniaSharedState from '@common/stores/plugin/sharedState'

const store: Pinia = createPinia()
store.use(PiniaSharedState({ enabled: false }))

export default function initializeStore(app: App) {
  app.use(store)
}

export { store }
