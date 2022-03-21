// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'
import { plugin as formPlugin, bindings as bindingsPlugin } from '@formkit/vue'
import type { FormKitConfig, FormKitPlugin } from '@formkit/core'
import type {
  ImportGlobEagerOutput,
  ImportGlobEagerDefault,
} from '@common/types/utils'
import createFieldPlugin from '@common/form/core/createFieldPlugin'
import type {
  FormAppSpecificTheme,
  FormFieldTypeImportModules,
} from '@common/types/form'
import createValidationPlugin from '@common/form/core/createValidationPlugin'
import createI18nPlugin from '@common/form/core/createI18nPlugin'
import '@formkit/dev'
import createTailwindClasses from '@common/form/core/createTailwindClasses'

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
  import.meta.globEager('./plugins/global/*.ts')
const plugins = getFormPlugins(pluginModules)

export const buildFormKitPluginConfig = (
  config?: FormKitConfig,
  appSpecificFieldModules: ImportGlobEagerOutput<FormFieldTypeImportModules> = {},
  appSpecificPlugins: FormKitPlugin[] = [],
  appSpecificTheme: FormAppSpecificTheme = {},
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
    config: {
      classes: createTailwindClasses(appSpecificTheme),
      ...config,
    },
  }
}

export default function initializeForm(
  app: App,
  appSpecificConfig?: FormKitConfig,
  appSpecificFieldModules: ImportGlobEagerOutput<FormFieldTypeImportModules> = {},
  appSpecificPlugins: FormKitPlugin[] = [],
  appSpecificTheme: FormAppSpecificTheme = {},
) {
  app.use(
    formPlugin,
    buildFormKitPluginConfig(
      appSpecificConfig,
      appSpecificFieldModules,
      appSpecificPlugins,
      appSpecificTheme,
    ),
  )
}
