// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineAsyncComponent, type App } from 'vue'

import { initializeFileClasses } from '#shared/components/Form/fields/FieldFile/initializeFileClasses.ts'
import { initializeToggleClasses } from '#shared/components/Form/fields/FieldToggle/initializeToggleClasses.ts'
import {
  initializeFieldEditorClasses,
  initializeEditorComponents,
} from '#shared/components/Form/initializeFieldEditor.ts'
import { initializeFieldLinkClasses } from '#shared/components/Form/initializeFieldLinkClasses.ts'
import { initializeFormClasses } from '#shared/components/Form/initializeFormClasses.ts'
import { initializeFormGroupClasses } from '#shared/components/Form/initializeFormGroupClasses.ts'
import mainInitializeForm, { getFormPlugins } from '#shared/form/index.ts'
import type {
  FormFieldTypeImportModules,
  FormThemeExtension,
  InitializeAppForm,
} from '#shared/types/form.ts'
import type { ImportGlobEagerOutput } from '#shared/types/utils.ts'

import FieldEditorSuggestionList from '#desktop/components/Form/fields/FieldEditor/FieldEditorSuggestionList.vue'

import { getCoreDesktopClasses } from './theme/global/getCoreDesktopClasses.ts'

import type { FormKitPlugin } from '@formkit/core'

const pluginModules: ImportGlobEagerOutput<FormKitPlugin> = import.meta.glob(
  './plugins/global/*.ts',
  { eager: true },
)
export const desktopFormFieldModules: ImportGlobEagerOutput<FormFieldTypeImportModules> =
  import.meta.glob('../components/Form/fields/**/index.ts', { eager: true })
const themeExtensionModules: ImportGlobEagerOutput<FormThemeExtension> = import.meta.glob(
  './theme/global/extensions/*.ts',
  { eager: true },
)

export const initializeForm: InitializeAppForm = (app: App) => {
  const plugins = getFormPlugins(pluginModules)
  const theme = {
    coreClasses: getCoreDesktopClasses,
    extensions: themeExtensionModules,
  }

  const decoratorIcons = {
    checkboxDecorator:
      '<svg width="16" height="16" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg" class="w-3 h-3 fill-current"><path d="M10.9696 4.96967C11.2625 4.67678 11.7374 4.67678 12.0303 4.96967C12.3196 5.25897 12.3231 5.72582 12.0409 6.01947L8.04873 11.0097C8.04297 11.0169 8.03682 11.0238 8.03029 11.0303C7.7374 11.3232 7.26253 11.3232 6.96963 11.0303L4.32319 8.38388C4.03029 8.09099 4.03029 7.61612 4.32319 7.32322C4.61608 7.03033 5.09095 7.03033 5.38385 7.32322L7.47737 9.41674L10.9497 4.9921C10.9559 4.98424 10.9626 4.97674 10.9696 4.96967Z" /></svg>',
  }

  mainInitializeForm(app, undefined, desktopFormFieldModules, plugins, theme, decoratorIcons)
}

export const initializeFormFields = () => {
  initializeFormClasses({
    loading: 'my-9 fill-yellow-300',
  })

  initializeFieldLinkClasses({
    container: 'formkit-link min-h-10 flex items-center',
    base: 'ms-2',
    link: 'w-min h-min min-h-min shrink-0 flex-nowrap items-center justify-center gap-x-1 border-0 font-normal shadow-none transition-transform duration-200 hover:outline-1 hover:outline-offset-1 hover:outline-blue-600 focus:outline-0 focus:hover:outline-1 focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 focus:active:scale-[95%] dark:hover:outline-blue-900 text-blue-800 hover:text-blue-850 dark:hover:text-blue-600 text-base p-2 rounded-lg',
  })

  initializeFormGroupClasses({
    container: 'form-group grid grid-cols-2 gap-y-2.5 gap-x-3',
    help: 'text-xs',
    dirtyMark: 'form-group-mark-dirty',
    bottomMargin: 'mb-4 last:mb-0',
  })

  initializeToggleClasses({
    track:
      'bg-stone-200 dark:bg-gray-500 ring-1 ring-neutral-100 dark:ring-gray-900 hover:outline hover:outline-1 hover:outline-offset-2 hover:outline-blue-600 dark:hover:outline-blue-900 focus:outline focus:outline-1 focus:outline-offset-2 focus:outline-blue-800 hover:focus:outline-blue-800 dark:hover:focus:outline-blue-800 formkit-invalid:outline formkit-invalid:outline-1 formkit-invalid:outline-offset-2 formkit-invalid:outline-red-500 dark:hover:formkit-invalid:outline-red-500 formkit-errors:outline formkit-errors:outline-1 formkit-errors:outline-offset-2 formkit-errors:outline-red-500 dark:hover:formkit-errors:outline-red-500',
    trackOn: 'bg-blue-800!',
    knob: 'bg-white',
  })

  initializeFieldEditorClasses({
    actionBar: {
      tableMenuContainer:
        'gap-1 p-2 focus:outline focus:outline-1 focus:outline-offset-2 rounded-md focus:outline-blue-800',
      tableMenuGrid: 'gap-1',
      button: {
        base: 'focus-visible-app-default dark:hover:bg-blue-900 hover:bg-blue-600 rounded-lg dark:hover:text-white hover:text-black transition-color',
      },
    },
    input: {
      container:
        'px-2.5 py-2 formkit-invalid:outline formkit-invalid:outline-1 formkit-invalid:-outline-offset-1 formkit-errors:-outline-offset-1  formkit-invalid:outline-red-500 formkit-errors:outline formkit-errors:outline-1 formkit-errors:outline-red-500 formkit-warning:outline-1 formkit-warning:outline-yellow-600! formkit-warning:-outline-offset-1 ',
      inlineContainer: 'px-1.5! py-1!',
    },
    tableMenu: {
      triggerButton:
        'w-6 h-6 flex items-center justify-center bg-blue-800/80 text-black dark:text-white',
    },
  })

  initializeEditorComponents({
    actionBar: defineAsyncComponent(
      () => import('#desktop/components/Form/fields/FieldEditor/FieldEditorActionBar.vue'),
    ),
    actionMenu: defineAsyncComponent(
      () => import('#desktop/components/Form/fields/FieldEditor/FieldEditorActionMenu.vue'),
    ),
    suggestionList: FieldEditorSuggestionList,
  })

  initializeFileClasses({
    button: 'disabled:opacity-60',
    divider: 'bg-neutral-100 dark:bg-gray-900',
    listContainer: 'max-h-96',
    dropZoneContainer: 'bg-blue-200 dark:bg-gray-700',
    dropZoneBorder: 'border-blue-800',
  })
}
