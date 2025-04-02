// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { createApp } from 'vue'

import '#mobile/styles/main.css'

import { initializeAppName } from '#shared/composables/useAppName.ts'
import { useForceDesktop } from '#shared/composables/useForceDesktop.ts'
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

import { initializeForm, initializeFormFields } from '#mobile/form/index.ts'
import { initializeGlobalComponentStyles } from '#mobile/initializer/initializeGlobalComponentStyles.ts'
import initializeGlobalDirectives from '#mobile/initializer/initializeGlobalDirectives.ts'
import { initializeMobileIcons } from '#mobile/initializer/initializeMobileIcons.ts'
import { initializeMobileVisuals } from '#mobile/initializer/mobileVisuals.ts'
import initializeRouter from '#mobile/router/index.ts'
import initializeApolloClient from '#mobile/server/apollo/index.ts'

import App from './AppMobile.vue'
import { ensureAfterAuth } from './pages/authentication/after-auth/composable/useAfterAuthPlugins.ts'

const { forceDesktopLocalStorage } = useForceDesktop()

// If the user explicitly switched to the desktop app the last time around,
//   redirect them automatically, before hoisting the app.
if (forceDesktopLocalStorage.value) window.location.href = '/'

export default async function mountApp(): Promise<void> {
  const app = createApp(App)
  initializeAppName('mobile')

  initializeApolloClient(app)

  const router = initializeRouter(app)

  // Remember the initialized router.
  setCurrentRouter(router)

  initializeStore(app)
  initializeMobileIcons()
  initializeForm(app)
  initializeFormFields()
  initializeGlobalComponentStyles()
  initializeGlobalComponents(app)
  initializeGlobalProperties(app)
  initializeGlobalDirectives(app)
  initializeMobileVisuals()
  initializeStoreSubscriptions()

  initializeAbstracts({
    durations: { normal: { enter: 300, leave: 200 } },
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

  if (VITE_TEST_MODE) {
    await import('#shared/initializer/initializeFakeTimer.ts')
  }

  app.mount('#app')

  if (session.afterAuth) {
    await ensureAfterAuth(router, session.afterAuth)
  }
}
