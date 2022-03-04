// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'
import type {
  FormKitClasses,
  FormKitFrameworkContext,
  FormKitPlugin,
  FormKitSchemaCondition,
  FormKitSchemaNode,
  FormKitTypeDefinition,
} from '@formkit/core'
import type {
  FormKitValidationRule,
  FormKitValidationMessages,
  FormKitValidationRules,
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

// https://formkit.com/essentials/validation#showing-errors
export enum FormValidationVisibility {
  'blur' = 'blur',
  'live' = 'live',
  'dirty' = 'dirty',
  'submit' = 'submit',
}

interface FormFieldAdditionalProps {
  [index: string]: unknown
}

export interface FormDefaultProps {
  formId: string
  labelPlaceholder: string[]
}

export interface FormSchemaField extends FormFieldAdditionalProps {
  type: string
  name: string
  value?: unknown
  label: string
  config?: Record<string, unknown>
  classes?: Record<string, string | Record<string, boolean> | FormKitClasses>
  delay?: number
  errors?: string[]
  inputErrors?: Record<string, string[]>
  id?: string
  plugins?: FormKitPlugin[]
  sectionsSchema?: Record<
    string,
    Partial<FormKitSchemaNode> | FormKitSchemaCondition
  >
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  validation?: string | Array<[rule: string, ...args: any]>
  validationMessages?: FormKitValidationMessages
  validationRules?: FormKitValidationRules
  validationVisibility?: FormValidationVisibility
}

export interface FormSchemaLayout {
  isLayout: boolean
  children: FormSchemaField[]
  props: {
    columns?: number
  }
  // TODO: add addtional stuff, when the form layout component is more ready
}

export type FormSchemaNode = FormSchemaLayout | FormSchemaField
export interface ReactiveFormSchemData {
  fields: Record<string, FormSchemaField>
}

export type FormFieldContext<
  TFieldProps extends FormFieldAdditionalProps = FormFieldAdditionalProps,
> = FormKitFrameworkContext & FormDefaultProps & TFieldProps

export interface FormValues {
  [index: string]: unknown
}
