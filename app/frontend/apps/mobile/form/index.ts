// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'
import type { FormKitPlugin } from '@formkit/core'
import mainInitializeForm, { getFormPlugins } from '@shared/form'
import type {
  FormFieldTypeImportModules,
  FormThemeExtension,
  InitializeAppForm,
} from '@shared/types/form'
import type { ImportGlobEagerOutput } from '@shared/types/utils'
import getCoreClasses from './theme/global/getCoreClasses'

const pluginModules: ImportGlobEagerOutput<FormKitPlugin> = import.meta.glob(
  './plugins/global/*.ts',
  { eager: true },
)
const fieldModules: ImportGlobEagerOutput<FormFieldTypeImportModules> =
  import.meta.glob('../components/Form/fields/**/index.ts', { eager: true })
const themeExtensionModules: ImportGlobEagerOutput<FormThemeExtension> =
  import.meta.glob('./theme/global/extensions/*.ts', { eager: true })

const initializeForm: InitializeAppForm = (app: App) => {
  const plugins = getFormPlugins(pluginModules)
  const theme = {
    coreClasses: getCoreClasses,
    extensions: themeExtensionModules,
  }

  mainInitializeForm(app, undefined, fieldModules, plugins, theme)
}

export default initializeForm
