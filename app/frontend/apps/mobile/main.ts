// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { createApp, unref } from 'vue'
import '@shared/initializer/translatableMarker'
import App from '@mobile/App.vue'
import useSessionStore from '@shared/stores/session'
import '@mobile/styles/main.css'
import initializeApolloClient from '@mobile/server/apollo'
import initializeStore from '@shared/stores'
import initializeStoreSubscriptions from '@shared/initializer/storeSubscriptions'
import initializeGlobalComponents from '@shared/initializer/globalComponents'
import initializeRouter from '@mobile/router'
import useApplicationStore from '@shared/stores/application'
import { i18n } from '@shared/i18n'
import useLocaleStore from '@shared/stores/locale'
import useAuthenticationStore from '@shared/stores/authentication'
import 'virtual:svg-icons-register' // eslint-disable-line import/no-unresolved
import initializeForm from '@mobile/form'
import { storeToRefs } from 'pinia'

export default async function mountApp(): Promise<void> {
  const app = createApp(App)

  // TODO remove when Vue 3.3 released
  app.config.unwrapInjectedRef = true

  initializeApolloClient(app)

  initializeStore(app)
  initializeRouter(app)

  initializeGlobalComponents(app)

  initializeStoreSubscriptions()

  const session = useSessionStore()
  await session.checkSession()

  const application = useApplicationStore()
  const { config } = storeToRefs(application)

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
  app.config.globalProperties.$t = i18n.t.bind(i18n)
  Object.defineProperty(app.config.globalProperties, '$c', {
    enumerable: true,
    get: () => unref(config),
  })

  initializeForm(app)

  app.mount('#app')
}
