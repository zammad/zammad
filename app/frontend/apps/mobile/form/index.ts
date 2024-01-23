// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'
import type { FormKitPlugin } from '@formkit/core'
import mainInitializeForm, { getFormPlugins } from '#shared/form/index.ts'
import type {
  FormFieldTypeImportModules,
  FormThemeExtension,
  InitializeAppForm,
} from '#shared/types/form.ts'
import type { ImportGlobEagerOutput } from '#shared/types/utils.ts'
import { initializeFormClasses } from '#shared/components/Form/initializeFormClasses.ts'
import { initializeToggleClasses } from '#shared/components/Form/fields/FieldToggle/initializeToggleClasses.ts'
import getCoreClasses from './theme/global/getCoreMobileClasses.ts'

const pluginModules: ImportGlobEagerOutput<FormKitPlugin> = import.meta.glob(
  './plugins/global/*.ts',
  { eager: true },
)
export const mobileFormFieldModules: ImportGlobEagerOutput<FormFieldTypeImportModules> =
  import.meta.glob('../components/Form/fields/**/index.ts', { eager: true })
const themeExtensionModules: ImportGlobEagerOutput<FormThemeExtension> =
  import.meta.glob('./theme/global/extensions/*.ts', { eager: true })

export const initializeForm: InitializeAppForm = (app: App) => {
  const plugins = getFormPlugins(pluginModules)
  const theme = {
    coreClasses: getCoreClasses,
    extensions: themeExtensionModules,
  }

  mainInitializeForm(app, undefined, mobileFormFieldModules, plugins, theme)
}

export const initializeFormFields = () => {
  initializeFormClasses({
    loading: 'my-4',
  })

  initializeToggleClasses({
    track:
      'bg-gray-300 border border-transparent focus-within:ring-1 focus-within:ring-white focus-within:ring-opacity-75 focus:outline-none formkit-invalid:border-solid formkit-invalid:border-red',
    trackOn: '!bg-blue',
    knob: 'bg-white shadow-lg ring-0',
  })
}
