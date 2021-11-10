// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { App } from 'vue'
import { createPinia, Pinia } from 'pinia'

const store: Pinia = createPinia()

export default function initializeStore(app: App) {
  app.use(store)
}

export { store }
