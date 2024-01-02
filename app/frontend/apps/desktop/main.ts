// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { createApp } from 'vue'

import '#desktop/styles/main.scss'

import { useSessionStore } from '#shared/stores/session.ts'
import initializeStoreSubscriptions from '#shared/initializer/storeSubscriptions.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import { useAppTheme } from '#shared/stores/theme.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import initializeStore from '#shared/stores/index.ts'
import initializeGlobalComponents from '#shared/initializer/globalComponents.ts'
import { initializeAppName } from '#shared/composables/useAppName.ts'
import initializeGlobalProperties from '#shared/initializer/globalProperties.ts'

import { initializeDesktopIcons } from '#desktop/initializer/initializeDesktopIcons.ts'
import { initializeGlobalComponentStyles } from '#desktop/initializer/initializeGlobalComponentStyles.ts'
import initializeApolloClient from '#desktop/server/apollo/index.ts'
import initializeRouter from '#desktop/router/index.ts'
import initializeForm from '#desktop/form/index.ts'

import { ensureAfterAuth } from './pages/login/after-auth/composable/useAfterAuthPlugins.ts'

import App from './AppDesktop.vue'

export const mountApp = async () => {
  const app = createApp(App)

  initializeApolloClient(app)
  const router = initializeRouter(app)
  initializeStore(app)
  initializeDesktopIcons()
  initializeForm(app)
  initializeGlobalComponentStyles()
  initializeGlobalComponents(app)
  initializeAppName('desktop')
  initializeGlobalProperties(app)
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

  // sync theme so the store is initialized and user (if exists) and DOM have the same value
  useAppTheme().syncTheme()

  if (VITE_TEST_MODE) {
    await import('#shared/initializer/initializeFakeTimer.ts')
  }

  app.mount('#app')

  if (session.afterAuth) {
    await ensureAfterAuth(router, session.afterAuth)
  }
}
