// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'

import initializeApolloClient from '@mobile/server/apollo'
import initializeStore from '@shared/stores'
import initializeGlobalComponents from '@shared/initializer/globalComponents'
import initializeForm from '@mobile/form'
import initializeGlobalProperties from '@shared/initializer/globalProperties'

export default function initializeApp(app: App) {
  // TODO remove when Vue 3.3 released
  app.config.unwrapInjectedRef = true

  initializeApolloClient(app)
  initializeStore(app)
  initializeGlobalComponents(app)
  initializeGlobalProperties(app)
  initializeForm(app)

  return app
}
