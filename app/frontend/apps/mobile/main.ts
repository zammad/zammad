// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { createApp } from 'vue'
import initializeApp from '#mobile/initialize.ts'
import App from '#mobile/App.vue'
import { useSessionStore } from '#shared/stores/session.ts'
import initializeStoreSubscriptions from '#shared/initializer/storeSubscriptions.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import initializeApolloClient from '#mobile/server/apollo/index.ts'
import initializeRouter from '#mobile/router/index.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import { useForceDesktop } from '#shared/composables/useForceDesktop.ts'
import { ensureAfterAuth } from './pages/login/after-auth/composable/useAfterAuthPlugins.ts'

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
  const authentication = useAuthenticationStore()

  // If the session is invalid, clear the already set authentication flag from storage.
  if (!(await session.checkSession()) && authentication.authenticated) {
    authentication.authenticated = false
  }

  const application = useApplicationStore()

  const initalizeAfterSessionCheck: Array<Promise<unknown>> = [
    application.getConfig(),
  ]

  if (session.id) {
    authentication.authenticated = true
    initalizeAfterSessionCheck.push(session.getCurrentUser())
  }

  await Promise.all(initalizeAfterSessionCheck)

  if (session.id) session.initialized = true

  const locale = useLocaleStore()

  if (!locale.localeData) {
    await locale.setLocale()
  }

  app.mount('#app')

  console.log('session', session)
  if (session.afterAuth) {
    await ensureAfterAuth(router, session.afterAuth)
  }
}
