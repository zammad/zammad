// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type {
  FormValidationRules,
  FormValidationRuleType,
} from '@common/types/form'
import type {
  ImportGlobEagerDefault,
  ImportGlobEagerOutput,
} from '@common/types/utils'
import type { FormKitPlugin } from '@formkit/core'
import * as defaultRules from '@formkit/rules'
import {
  createValidationPlugin as formKitCreateValidationPlugin,
  type FormKitValidationMessages,
} from '@formkit/validation'

const ruleModules: ImportGlobEagerOutput<FormValidationRuleType> =
  import.meta.globEager('../validation/rules/*.ts')

const createValidationPlugin = (): FormKitPlugin => {
  const rules: FormValidationRules = {}

  Object.values(ruleModules).forEach(
    (module: ImportGlobEagerDefault<FormValidationRuleType>) => {
      const validationRule = module.default

      rules[validationRule.ruleType] = validationRule.rule
    },
  )

  return formKitCreateValidationPlugin({
    ...defaultRules,
    ...rules,
  })
}

export default createValidationPlugin

export const getValidationRuleMessages = (): FormKitValidationMessages => {
  const ruleLocaleMessages: FormKitValidationMessages = {}

  Object.values(ruleModules).forEach(
    (module: ImportGlobEagerDefault<FormValidationRuleType>) => {
      const validationRule = module.default

      ruleLocaleMessages[validationRule.ruleType] = validationRule.localeMessage
    },
  )

  return ruleLocaleMessages
}
