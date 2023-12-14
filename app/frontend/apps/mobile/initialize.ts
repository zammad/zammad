// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'

import '#mobile/styles/main.scss'

import initializeStore from '#shared/stores/index.ts'
import initializeGlobalComponents from '#shared/initializer/globalComponents.ts'
import { initializeAppName } from '#shared/composables/useAppName.ts'
import initializeGlobalProperties from '#shared/initializer/globalProperties.ts'
import initializeForm from '#mobile/form/index.ts'
import { initializeMobileVisuals } from './initializer/mobileVisuals.ts'
import { initializeMobileIcons } from './initializer/initializeMobileIcons.ts'
import { initializeGlobalComponentStyles } from './initializer/initializeGlobalComponentStyles.ts'

export default function initializeApp(app: App) {
  initializeAppName('mobile')
  initializeStore(app)
  initializeGlobalComponentStyles()
  initializeGlobalComponents(app)
  initializeGlobalProperties(app)
  initializeMobileIcons()
  initializeForm(app)
  initializeMobileVisuals()

  return app
}
