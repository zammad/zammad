// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { createThemePlugin } from '@formkit/themes'
import { plugin as formPlugin, bindings as bindingsPlugin } from '@formkit/vue'

import '@formkit/dev'
import type {
  FormAppSpecificTheme,
  FormDecoratorIcons,
  FormFieldTypeImportModules,
} from '#shared/types/form.ts'
import type {
  ImportGlobEagerOutput,
  ImportGlobEagerDefault,
} from '#shared/types/utils.ts'

import createCustomIcons from './core/createCustomIcons.ts'
import createFieldPlugin from './core/createFieldPlugin.ts'
import createI18nPlugin from './core/createI18nPlugin.ts'
import createTailwindClasses from './core/createTailwindClasses.ts'
import createValidationPlugin from './core/createValidationPlugin.ts'

import type { FormKitConfig, FormKitPlugin } from '@formkit/core'
import type { App } from 'vue'

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

const pluginModules: ImportGlobEagerOutput<FormKitPlugin> = import.meta.glob(
  './plugins/global/*.ts',
  { eager: true },
)
const plugins = getFormPlugins(pluginModules)

const checkIcon =
  '<svg width="16" height="16" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" class="fill-current"><path d="M20.8087 5.58815L11.3542 18.5881C11.1771 18.8316 10.8998 18.9824 10.5992 18.9985C10.2986 19.0147 10.0067 18.8946 9.80449 18.6715L3.25903 11.4493L4.74097 10.1062L10.4603 16.4169L19.1913 4.4118L20.8087 5.58815Z" /></svg>'

export const buildFormKitPluginConfig = (
  config?: FormKitConfig,
  appSpecificFieldModules: ImportGlobEagerOutput<FormFieldTypeImportModules> = {},
  appSpecificPlugins: FormKitPlugin[] = [],
  appSpecificTheme: FormAppSpecificTheme = {},
  appSpecificDecoratorIcons: FormDecoratorIcons = {},
) => {
  const customIcons = createCustomIcons()

  return {
    plugins: [
      createFieldPlugin(appSpecificFieldModules),
      bindingsPlugin,
      createI18nPlugin(),
      createValidationPlugin(),
      createThemePlugin(
        undefined,
        {
          checkboxDecorator:
            appSpecificDecoratorIcons.checkboxDecorator || checkIcon,
          radioDecorator: appSpecificDecoratorIcons.radioDecorator || checkIcon,
          ...customIcons,
        },
        undefined,
        () => undefined,
      ),
      ...plugins,
      ...appSpecificPlugins,
    ],
    locale: 'staticLocale',
    config: {
      classes: createTailwindClasses(appSpecificTheme),
      ...config,
    },
    props: {
      dirtyBehavior: 'compare',
    },
  }
}

export default function initializeForm(
  app: App,
  appSpecificConfig?: FormKitConfig,
  appSpecificFieldModules: ImportGlobEagerOutput<FormFieldTypeImportModules> = {},
  appSpecificPlugins: FormKitPlugin[] = [],
  appSpecificTheme: FormAppSpecificTheme = {},
  appSpecificDecoratorIcons: FormDecoratorIcons = {},
) {
  app.use(
    formPlugin,
    buildFormKitPluginConfig(
      appSpecificConfig,
      appSpecificFieldModules,
      appSpecificPlugins,
      appSpecificTheme,
      appSpecificDecoratorIcons,
    ),
  )
}
