// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'
import type {
  FormKitClasses,
  FormKitFrameworkContext,
  FormKitGroupValue,
  FormKitPlugin,
  FormKitSchemaAttributes,
  FormKitSchemaCondition,
  FormKitSchemaNode,
  FormKitTypeDefinition,
} from '@formkit/core'
import type {
  FormKitValidationRule,
  FormKitValidationMessages,
  FormKitValidationRules,
} from '@formkit/validation'
import { ImportGlobEagerOutput } from '@common/types/utils'

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
  validationVisibility?: Exclude<
    FormValidationVisibility,
    FormValidationVisibility.submit
  >
}

interface FormSchemaLayoutBase {
  isLayout: boolean
}

export interface FormSchemaComponent extends FormSchemaLayoutBase {
  component: string
  props?: {
    [index: string]: unknown
  }
}

export interface FormSchemaDOMElement extends FormSchemaLayoutBase {
  element: string
  attrs?: FormKitSchemaAttributes
}

export type FormSchemaLayout = (FormSchemaComponent | FormSchemaDOMElement) & {
  children: (FormSchemaLayout | FormSchemaField | string)[] | string
}

export type FormSchemaNode = FormSchemaLayout | FormSchemaField
export interface ReactiveFormSchemData {
  fields: Record<string, FormSchemaField>
}

export type FormFieldContext<TFieldProps = FormFieldAdditionalProps> =
  FormKitFrameworkContext & FormDefaultProps & TFieldProps

export interface FormValues {
  [index: string]: unknown
}

export type FormData<TFormValues = FormValues> = FormKitGroupValue & TFormValues
