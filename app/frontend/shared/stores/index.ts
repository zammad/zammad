// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'
import { createPinia, type Pinia } from 'pinia'
import type { UsedStore } from '@shared/types/store'
import PiniaSharedState from './plugins/sharedState'

declare module 'pinia' {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  export interface DefineStoreOptionsBase<S, Store> {
    requiresAuth?: boolean
  }
}

const usedStores = new Set<UsedStore>()

const pinia: Pinia = createPinia()
pinia.use(PiniaSharedState({ enabled: false }))

// Remember all stores, for example to cleanup the private stores after logout.
pinia.use((context) => {
  usedStores.add({
    store: context.store,
    requiresAuth: context.options.requiresAuth ?? true,
  })
})

export default function initializeStore(app: App) {
  app.use(pinia)
}

export const resetAndDisposeStores = (requiresAuth?: boolean) => {
  usedStores.forEach((usedStore) => {
    if (requiresAuth !== undefined && usedStore.requiresAuth !== requiresAuth) {
      return
    }

    usedStore.store.$dispose()
    delete pinia.state.value[usedStore.store.$id]
    usedStores.delete(usedStore)
  })
}

export { pinia }
