// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { createApp } from 'vue'
import '@shared/initializer/translatableMarker'
import App from '@mobile/App.vue'
import { useSessionStore } from '@shared/stores/session'
import '@mobile/styles/main.scss'
import initializeStoreSubscriptions from '@shared/initializer/storeSubscriptions'
import useApplicationStore from '@shared/stores/application'
import useLocaleStore from '@shared/stores/locale'
import initializeRouter from '@mobile/router'
import useAuthenticationStore from '@shared/stores/authentication'
import 'virtual:svg-icons-register' // eslint-disable-line import/no-unresolved
import initializeApp from './initialize'

export default async function mountApp(): Promise<void> {
  const app = createApp(App)

  initializeApp(app)
  initializeRouter(app)

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
