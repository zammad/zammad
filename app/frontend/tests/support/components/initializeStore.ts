// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { createTestingPinia } from '@pinia/testing'

import { useApplicationStore } from '#shared/stores/application.ts'

import type { TestingPinia } from '@pinia/testing'
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
  app.config.product_logo = 'logo.svg'
  app.config.ui_ticket_overview_ticket_limit = 5
  app.config.product_name = 'Zammad'
  app.config.api_path = '/api'
  app.config.pretty_date_format = 'relative'
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
