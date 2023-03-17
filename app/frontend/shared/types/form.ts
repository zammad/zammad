// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'
import type { FormKitTypeDefinition } from '@formkit/core'
import type {
  FormKitValidationRule,
  FormKitValidationMessages,
} from '@formkit/validation'
import type { RouteLocationRaw } from 'vue-router'
import type { ImportGlobEagerOutput } from './utils'

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
}

export type FormUpdaterTrigger = 'direct' | 'delayed' | 'blur'
