// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitPlugin } from '@formkit/core'
import * as defaultRules from '@formkit/rules'
import {
  createValidationPlugin as formKitCreateValidationPlugin,
  type FormKitValidationMessages,
} from '@formkit/validation'
import type {
  FormValidationRules,
  FormValidationRuleType,
} from '@shared/types/form'
import type {
  ImportGlobEagerDefault,
  ImportGlobEagerOutput,
} from '@shared/types/utils'

const ruleModules: ImportGlobEagerOutput<FormValidationRuleType> =
  import.meta.glob('../validation/rules/*.ts', { eager: true })

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
