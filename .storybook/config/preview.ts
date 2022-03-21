// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import '@common/initializer/translatableMarker'
import initializeGlobalComponents from '@common/initializer/globalComponents'
import '@common/styles/main.css'
import { i18n } from '@common/utils/i18n'
import { app } from '@storybook/vue3'
import 'virtual:svg-icons-register' // eslint-disable-line import/no-unresolved
import initializeStore from '@common/stores'
import initializeForm, { getFormPlugins } from '@common/form'
import type { ImportGlobEagerOutput } from '@common/types/utils'
import type { FormKitPlugin } from '@formkit/core'
import getMobileCoreClasses from '@mobile/form/theme/global'
import { createRouter, createWebHashHistory, type Router } from 'vue-router'
import type {
  FormFieldTypeImportModules,
  FormThemeExtension,
} from '@common/types/form'

// Adds the translations to storybook.
app.config.globalProperties.i18n = i18n

// Initialize the needed core components and plugins.
initializeGlobalComponents(app)
initializeStore(app)

// Initialize the FormKit plugin witht he needed fields ands internal FormKit plugins.
const mobilePluginModules: ImportGlobEagerOutput<FormKitPlugin> =
  import.meta.globEager('../app/frontend/apps/mobile/form/plugins/global/*.ts')
const mobileFieldModules: ImportGlobEagerOutput<FormFieldTypeImportModules> =
  import.meta.globEager(
    '../app/frontend/apps/mobile/components/form/field/**/*.ts',
  )
const themeExtensionModules: ImportGlobEagerOutput<FormThemeExtension> =
  import.meta.globEager(
    '../app/frontend/apps/mobile/form/theme/global/extensions/*.ts',
  )

const plugins = getFormPlugins(mobilePluginModules)

const appTheme = {
  coreClasses: getMobileCoreClasses,
  extensions: themeExtensionModules,
}

initializeForm(app, undefined, mobileFieldModules, plugins, appTheme)

const router: Router = createRouter({
  history: createWebHashHistory(),
  routes: [],
})
app.use(router)

export default {
  actions: { argTypesRegex: '^on[A-Z].*' },
  controls: {
    matchers: {
      color: /(background|color)$/i,
      date: /Date$/,
    },
  },
}
