// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitPlugin } from '@formkit/core'
import loadLocales from '@common/form/i18n/locales'
import { createI18nPlugin as formKitCreateI18nPlugin } from '@formkit/i18n'
import { getValidationRuleMessages } from '@common/form/core/createValidationPlugin'
import { reactive } from 'vue'

const createI18nPlugin = (): FormKitPlugin => {
  const staticLocale = reactive(loadLocales())

  Object.assign(staticLocale.validation, getValidationRuleMessages())

  return formKitCreateI18nPlugin({ staticLocale })
}

export default createI18nPlugin
