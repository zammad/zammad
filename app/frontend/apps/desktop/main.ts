// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { createApp } from 'vue'

import '#desktop/styles/main.css'

import { initializeAppName } from '#shared/composables/useAppName.ts'
import { initializeTwoFactorPlugins } from '#shared/entities/two-factor/composables/initializeTwoFactorPlugins.ts'
import initializeGlobalComponents from '#shared/initializer/globalComponents.ts'
import initializeGlobalProperties from '#shared/initializer/globalProperties.ts'
import { initializeAbstracts } from '#shared/initializer/initializeAbstracts.ts'
import initializeStoreSubscriptions from '#shared/initializer/storeSubscriptions.ts'
import { setCurrentRouter } from '#shared/router/router.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import initializeStore from '#shared/stores/index.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { twoFactorConfigurationPluginLookup } from '#desktop/entities/two-factor-configuration/plugins/index.ts'
import { initializeForm, initializeFormFields } from '#desktop/form/index.ts'
import { initializeDesktopVisuals } from '#desktop/initializer/desktopVisuals.ts'
import { initializeDesktopIcons } from '#desktop/initializer/initializeDesktopIcons.ts'
import { initializeGlobalComponentStyles } from '#desktop/initializer/initializeGlobalComponentStyles.ts'
import initializeGlobalDirectives from '#desktop/initializer/initializeGlobalDirectives.ts'
import { ensureAfterAuth } from '#desktop/pages/authentication/after-auth/composable/useAfterAuthPlugins.ts'
import initializeRouter from '#desktop/router/index.ts'
import initializeApolloClient from '#desktop/server/apollo/index.ts'
import { useThemeStore } from '#desktop/stores/theme.ts'

import App from './AppDesktop.vue'
import { setCurrentApp } from './currentApp.ts'

export const mountApp = async () => {
  const app = createApp(App)

  // Remember the current created app.
  setCurrentApp(app)

  initializeAppName('desktop')
  initializeApolloClient(app)

  const router = initializeRouter(app)

  // Remember the initialized router.
  setCurrentRouter(router)

  initializeStore(app)
  initializeDesktopIcons()
  initializeForm(app)
  initializeFormFields()
  initializeGlobalComponentStyles()
  initializeGlobalComponents(app)
  initializeGlobalProperties(app)
  initializeGlobalDirectives(app)
  initializeStoreSubscriptions()
  initializeDesktopVisuals()
  initializeTwoFactorPlugins(twoFactorConfigurationPluginLookup)
  initializeAbstracts({
    durations: {
      normal: { enter: 300, leave: 200 },
    },
  }) // :TODO move this argument to own config?

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
  useThemeStore().syncTheme()

  if (VITE_TEST_MODE) {
    await import('#shared/initializer/initializeFakeTimer.ts')
  }

  app.mount('#app')

  if (session.afterAuth) {
    await ensureAfterAuth(router, session.afterAuth)
  }
}
