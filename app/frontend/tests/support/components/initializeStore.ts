// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TestingPinia } from '@pinia/testing'
import { createTestingPinia } from '@pinia/testing'
import { useApplicationStore } from '@shared/stores/application'
import type { Store } from 'pinia'

let storeInitialized = false
let pinia: TestingPinia
export const getTestPinia = () => pinia
const stores = new Set<Store>()

export const initializeStore = () => {
  if (storeInitialized) return pinia

  pinia = createTestingPinia({ createSpy: vi.fn, stubActions: false })
  // plugins.push({ install: pinia.install })
  pinia.use((context) => {
    stores.add(context.store)
  })
  storeInitialized = true
  const app = useApplicationStore()
  app.config.api_path = '/api'
  return pinia
}

export const cleanupStores = () => {
  if (!storeInitialized) return

  stores.forEach((store) => {
    store.$dispose()
  })
  pinia.state.value = {}
  stores.clear()
}
