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

export default async function mountApp(): Promise<void> {
  const app = createApp(App)

  initializeApp(app)
  initializeRouter(app)
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
