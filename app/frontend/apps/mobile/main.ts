// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { createApp } from 'vue'
import initializeApp from '@mobile/initialize'
import App from '@mobile/App.vue'
import { useSessionStore } from '@shared/stores/session'
import initializeStoreSubscriptions from '@shared/initializer/storeSubscriptions'
import { useApplicationStore } from '@shared/stores/application'
import { useLocaleStore } from '@shared/stores/locale'
import initializeApolloClient from '@mobile/server/apollo'
import initializeRouter from '@mobile/router'
import { useAuthenticationStore } from '@shared/stores/authentication'
import { useForceDesktop } from '@shared/composables/useForceDesktop'

const { forceDesktopLocalStorage } = useForceDesktop()

// If the user explicitly switched to the desktop app the last time around,
//   redirect them automatically, before hoisting the app.
if (forceDesktopLocalStorage.value) window.location.href = '/'

export default async function mountApp(): Promise<void> {
  const app = createApp(App)

  const router = initializeRouter(app)

  Object.defineProperty(window, 'Router', { value: router, configurable: true })

  initializeApp(app)
  initializeApolloClient(app)

  initializeStoreSubscriptions()

  const session = useSessionStore()
  await session.checkSession()

  const application = useApplicationStore()

  const initalizeAfterSessionCheck: Array<Promise<unknown>> = [
    application.getConfig(),
  ]

  if (session.id) {
    useAuthenticationStore().authenticated = true
    initalizeAfterSessionCheck.push(session.getCurrentUser())
  }
  await Promise.all(initalizeAfterSessionCheck)

  const locale = useLocaleStore()

  if (!locale.localeData) {
    await locale.setLocale()
  }

  app.mount('#app')
}
