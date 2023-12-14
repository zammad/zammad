// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'
import type { FormKitPlugin } from '@formkit/core'
import mainInitializeForm, { getFormPlugins } from '#shared/form/index.ts'
import type {
  FormFieldTypeImportModules,
  FormThemeExtension,
  InitializeAppForm,
} from '#shared/types/form.ts'
import type { ImportGlobEagerOutput } from '#shared/types/utils.ts'
import { getCoreDesktopClasses } from './theme/global/getCoreDesktopClasses.ts'

const pluginModules: ImportGlobEagerOutput<FormKitPlugin> = import.meta.glob(
  './plugins/global/*.ts',
  { eager: true },
)
export const desktopFormFieldModules: ImportGlobEagerOutput<FormFieldTypeImportModules> =
  import.meta.glob('../components/Form/fields/**/index.ts', { eager: true })
const themeExtensionModules: ImportGlobEagerOutput<FormThemeExtension> =
  import.meta.glob('./theme/global/extensions/*.ts', { eager: true })

const initializeForm: InitializeAppForm = (app: App) => {
  const plugins = getFormPlugins(pluginModules)
  const theme = {
    coreClasses: getCoreDesktopClasses,
    extensions: themeExtensionModules,
  }

  const decoratorIcons = {
    checkboxDecorator:
      '<svg width="16" height="16" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" class="w-3 h-3 fill-current"><path d="M10.9696 4.96967C11.2625 4.67678 11.7374 4.67678 12.0303 4.96967C12.3196 5.25897 12.3231 5.72582 12.0409 6.01947L8.04873 11.0097C8.04297 11.0169 8.03682 11.0238 8.03029 11.0303C7.7374 11.3232 7.26253 11.3232 6.96963 11.0303L4.32319 8.38388C4.03029 8.09099 4.03029 7.61612 4.32319 7.32322C4.61608 7.03033 5.09095 7.03033 5.38385 7.32322L7.47737 9.41674L10.9497 4.9921C10.9559 4.98424 10.9626 4.97674 10.9696 4.96967Z" /></svg>',
  }

  mainInitializeForm(
    app,
    undefined,
    desktopFormFieldModules,
    plugins,
    theme,
    decoratorIcons,
  )
}

export default initializeForm
