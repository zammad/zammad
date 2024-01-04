// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { reactive } from 'vue'
import type { FormKitPlugin } from '@formkit/core'
import { createI18nPlugin as formKitCreateI18nPlugin } from '@formkit/i18n'
import loadLocales from '#shared/form/i18n/locales.ts'
import { getValidationRuleMessages } from './createValidationPlugin.ts'

const createI18nPlugin = (): FormKitPlugin => {
  const staticLocale = reactive(loadLocales())

  Object.assign(staticLocale.validation, getValidationRuleMessages())

  return formKitCreateI18nPlugin({ staticLocale })
}

export default createI18nPlugin
