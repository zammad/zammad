// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'
import { plugin as formPlugin, bindings as bindingsPlugin } from '@formkit/vue'
import type { FormKitPlugin } from '@formkit/core'
import type {
  ImportGlobEagerOutput,
  ImportGlobEagerDefault,
} from '@common/types/utils'
import createFieldPlugin from '@common/form/core/createFieldPlugin'
import type { FormFieldTypeImportModules } from '@common/types/form'
import createValidationPlugin from '@common/form/core/createValidationPlugin'
import createI18nPlugin from '@common/form/core/createI18nPlugin'
import '@formkit/dev'

export const getFormPlugins = (
  modules: ImportGlobEagerOutput<FormKitPlugin>,
): FormKitPlugin[] => {
  const plugins: Array<FormKitPlugin> = []

  Object.values(modules).forEach(
    (module: ImportGlobEagerDefault<FormKitPlugin>) => {
      const plugin = module.default
      plugins.push(plugin)
    },
  )

  return plugins
}

const pluginModules: ImportGlobEagerOutput<FormKitPlugin> =
  import.meta.globEager('./plugins/*.ts')
const plugins = getFormPlugins(pluginModules)

export const buildFormKitPluginConfig = (
  appSpecificFieldModules: ImportGlobEagerOutput<FormFieldTypeImportModules> = {},
  appSpecificPlugins: FormKitPlugin[] = [],
) => {
  return {
    plugins: [
      createFieldPlugin(appSpecificFieldModules),
      bindingsPlugin,
      createI18nPlugin(),
      createValidationPlugin(),
      ...plugins,
      ...appSpecificPlugins,
    ],
    locale: 'staticLocale',
  }
}

export default function initializeForm(
  app: App,
  appSpecificFieldModules: ImportGlobEagerOutput<FormFieldTypeImportModules> = {},
  appSpecificPlugins: FormKitPlugin[] = [],
) {
  app.use(
    formPlugin,
    buildFormKitPluginConfig(appSpecificFieldModules, appSpecificPlugins),
  )
}
