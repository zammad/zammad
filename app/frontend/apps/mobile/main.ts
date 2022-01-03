// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { createApp } from 'vue'
import App from '@mobile/App.vue'
import {
  DefaultApolloClient,
  provideApolloClient,
} from '@vue/apollo-composable'
import apolloClient from '@common/server/apollo/client'
import useSessionIdStore from '@common/stores/session/id'
import '@common/styles/main.css'
import initializeStore from '@common/stores'
import initializeStoreSubscriptions from '@common/initializer/storeSubscriptions'
import initializeRouter from '@common/router/index'
import initializeGlobalComponents from '@common/initializer/globalComponents'
import routes from '@mobile/router'
import useApplicationConfigStore from '@common//stores/application/config'
import { i18n } from '@common/utils/i18n'
import useLocaleStore from '@common/stores/locale'
import useSessionUserStore from '@common/stores/session/user'
import useAuthenticatedStore from '@common/stores/authenticated'
import 'virtual:svg-icons-register' // eslint-disable-line import/no-unresolved
import transitionViewGuard from '@mobile/router/guards/before/viewTransition'

const enableLoadingAnimation = (): void => {
  const loadingElement: Maybe<HTMLElement> =
    document.getElementById('loadingApp')

  if (loadingElement) {
    loadingElement.style.display = 'flex'
  }
}

export default async function mountApp(): Promise<void> {
  const app = createApp(App)

  enableLoadingAnimation()

  app.provide(DefaultApolloClient, apolloClient)

  provideApolloClient(apolloClient)

  initializeStore(app)
  const router = initializeRouter(app, routes)

  // Add app custom specific guards.
  router.beforeEach(transitionViewGuard)

  initializeGlobalComponents(app)

  initializeStoreSubscriptions()

  const sessionId = useSessionIdStore()
  await sessionId.checkSession()

  const applicationConfig = useApplicationConfigStore()
  const sessionUser = useSessionUserStore()

  const initalizeAfterSessionCheck: Array<Promise<unknown>> = [
    applicationConfig.getConfig(),
  ]

  if (sessionId.value) {
    useAuthenticatedStore().value = true
    initalizeAfterSessionCheck.push(sessionUser.getCurrentUser())
  }
  await Promise.all(initalizeAfterSessionCheck)

  const locale = useLocaleStore()

  if (!locale.value) {
    await locale.updateLocale()
  }

  app.config.globalProperties.i18n = i18n

  app.mount('#app')
}
