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

import FieldEditorSuggestionList from '#mobile/components/Form/fields/FieldEditor/FieldEditorSuggestionList.vue'

import getCoreClasses from './theme/global/getCoreMobileClasses.ts'

import type { FormKitPlugin } from '@formkit/core'

const pluginModules: ImportGlobEagerOutput<FormKitPlugin> = import.meta.glob(
  './plugins/global/*.ts',
  { eager: true },
)
export const mobileFormFieldModules: ImportGlobEagerOutput<FormFieldTypeImportModules> =
  import.meta.glob('../components/Form/fields/**/index.ts', { eager: true })
const themeExtensionModules: ImportGlobEagerOutput<FormThemeExtension> = import.meta.glob(
  './theme/global/extensions/*.ts',
  { eager: true },
)

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

  initializeFormGroupClasses({
    container: 'form-group overflow-hidden rounded-xl bg-gray-500',
    help: 'text-xs text-gray-100 ltr:pl-3 rtl:pr-3',
    dirtyMark: 'form-group-mark-dirty',
    bottomMargin: 'mb-4',
  })

  initializeFieldLinkClasses({
    container: 'formkit-link flex items-center py-2',
    base: 'border-white/10 ltr:border-l ltr:pl-1 rtl:border-r rtl:pr-1',
    link: 'h-10 w-12',
  })

  initializeToggleClasses({
    track:
      'bg-gray-300 border border-transparent focus-within:ring-1 focus-within:ring-white focus-within:ring-opacity-75 focus:outline-hidden formkit-invalid:border-solid formkit-invalid:border-red',
    trackOn: '!bg-blue',
    knob: 'bg-white shadow-lg ring-0',
  })

  initializeFieldEditorClasses({
    actionBar: {
      tableMenuContainer: 'gap-2 p-4',
      tableMenuGrid: 'gap-2',
      button: {
        base: 'rounded-sm bg-black',
      },
    },
    input: {
      container: 'p-2',
      inlineContainer: '',
    },
    tableMenu: {
      triggerButton: 'w-7 h-7 flex items-center justify-center bg-blue/80 text-white',
    },
  })

  initializeEditorComponents({
    actionBar: defineAsyncComponent(
      () => import('#mobile/components/Form/fields/FieldEditor/FieldEditorActionBar.vue'),
    ),
    actionMenu: defineAsyncComponent(
      () => import('#mobile/components/Form/fields/FieldEditor/FieldEditorActionMenu.vue'),
    ),
    suggestionList: FieldEditorSuggestionList,
  })

  initializeFileClasses({
    button: 'disabled:text-blue/60 text-blue p-2.5 w-full',
    listContainer: 'max-h-48 px-4 pt-4',
  })
}
