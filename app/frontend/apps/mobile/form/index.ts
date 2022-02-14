// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import mainInitializeForm, { getFormPlugins } from '@common/form'
import type {
  FormFieldTypeImportModules,
  InitializeAppForm,
} from '@common/types/form'
import { ImportGlobEagerOutput } from '@common/types/utils'
import { FormKitPlugin } from '@formkit/core'
import { App } from 'vue'

const pluginModules: ImportGlobEagerOutput<FormKitPlugin> =
  import.meta.globEager('./plugins/*.ts')
const fieldModules: ImportGlobEagerOutput<FormFieldTypeImportModules> =
  import.meta.globEager('../components/form/field/**/*.ts')

const initializeForm: InitializeAppForm = (app: App) => {
  const plugins = getFormPlugins(pluginModules)

  mainInitializeForm(app, fieldModules, plugins)
}

export default initializeForm
