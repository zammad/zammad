// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ImportGlobEagerOutput } from './utils.ts'
import type { FormKitTypeDefinition } from '@formkit/core'
import type {
  FormKitValidationRule,
  FormKitValidationMessages,
} from '@formkit/validation'
import type { App } from 'vue'
import type { RouteLocationRaw } from 'vue-router'

export type InitializeAppForm = (app: App) => void

export type FormFieldsTypeDefinition = Record<string, FormKitTypeDefinition>
export type FormValidationRules = Record<string, FormKitValidationRule>

export type FormThemeClasses = Record<string, Record<string, string>>
export type FormThemeExtension = (classes: FormThemeClasses) => FormThemeClasses
export interface FormAppSpecificTheme {
  coreClasses?: FormThemeExtension
  extensions?: ImportGlobEagerOutput<FormThemeExtension>
}

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

export enum FormSchemaExtendType {
  Append = 'append',
  Prepend = 'prepend',
  Replace = 'replace',
  Merge = 'merge',
}

export interface FormDefaultProps {
  formId: string
  link?: RouteLocationRaw
  labelSrOnly?: boolean
  labelPlaceholder?: string[]
  internal?: boolean
  disabled?: boolean
}

export type FormUpdaterTrigger =
  | 'direct'
  | 'delayed'
  | 'blur'
  | 'form-reset'
  | 'manual'

export type FormUpdaterAdditionalParams = Record<string, unknown>

export interface FormUpdaterOptions {
  includeDirtyFields?: boolean
  additionalParams?: FormUpdaterAdditionalParams
}

export interface FormDecoratorIcons {
  checkboxDecorator?: string
  radioDecorator?: string
}
