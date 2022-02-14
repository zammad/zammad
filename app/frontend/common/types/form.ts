// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'
import type { Except, SetRequired } from 'type-fest'
import type { FormKitTypeDefinition } from '@formkit/core'
import type {
  FormKitValidationRule,
  FormKitValidationMessages,
} from '@formkit/validation'

export type InitializeAppForm = (app: App) => void

export type FormFieldsTypeDefinition = Record<string, FormKitTypeDefinition>
export type FormValidationRules = Record<string, FormKitValidationRule>

export interface FormFieldType {
  fieldType: string
  definition: FormKitTypeDefinition
}

export interface FormValidationRuleType {
  ruleType: string
  rule: FormKitValidationRule
  localeMessage: FormKitValidationMessages['index']
}

export type FormFieldTypeImportModules = FormFieldType | FormFieldType[]

export type FormCreateInputDefinitionOptions = SetRequired<
  Except<FormKitTypeDefinition, 'type'>,
  'props'
>
