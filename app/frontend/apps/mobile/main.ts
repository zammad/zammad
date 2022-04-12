// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { createApp } from 'vue'
import '@common/initializer/translatableMarker'
import App from '@mobile/App.vue'
import {
  DefaultApolloClient,
  provideApolloClient,
} from '@vue/apollo-composable'
import apolloClient from '@common/server/apollo/client'
import useSessionStore from '@common/stores/session'
import '@mobile/styles/main.css'
import initializeStore from '@common/stores'
import initializeStoreSubscriptions from '@common/initializer/storeSubscriptions'
import initializeRouter from '@common/router/index'
import initializeGlobalComponents from '@common/initializer/globalComponents'
import routes from '@mobile/router'
import useApplicationStore from '@common/stores/application'
import { i18n } from '@common/i18n'
import useLocaleStore from '@common/stores/locale'
import useAuthenticationStore from '@common/stores/authentication'
import 'virtual:svg-icons-register' // eslint-disable-line import/no-unresolved
import transitionViewGuard from '@mobile/router/guards/before/viewTransition'
import initializeForm from '@mobile/form'

export default async function mountApp(): Promise<void> {
  const app = createApp(App)

  app.provide(DefaultApolloClient, apolloClient)

  provideApolloClient(apolloClient)

  initializeStore(app)
  const router = initializeRouter(app, routes)

  // Add app custom specific guards.
  router.beforeEach(transitionViewGuard)

  initializeGlobalComponents(app)

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
    await locale.updateLocale()
  }

  app.config.globalProperties.i18n = i18n

  initializeForm(app)

  app.mount('#app')
}
