// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type {
  FormKitClasses,
  FormKitGroupValue,
  FormKitPlugin,
  FormKitSchemaAttributes,
  FormKitSchemaCondition,
  FormKitSchemaNode,
} from '@formkit/core'
import type {
  FormKitValidationMessages,
  FormKitValidationRules,
} from '@formkit/validation'
import type { Except } from 'type-fest'

export interface FormFieldAdditionalProps {
  [index: string]: unknown
}

// https://formkit.com/essentials/validation#showing-errors
export enum FormValidationVisibility {
  'blur' = 'blur',
  'live' = 'live',
  'dirty' = 'dirty',
  'submit' = 'submit',
}

export interface FormSchemaField {
  show?: boolean
  type: string
  name: string
  value?: unknown
  label?: string
  placeholder?: string
  help?: string
  disabled?: boolean
  delay?: number
  errors?: string[]
  id?: string
  sectionsSchema?: Record<
    string,
    Partial<FormKitSchemaNode> | FormKitSchemaCondition
  >
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  validation?: string | Array<[rule: string, ...args: any]>
  validationMessages?: FormKitValidationMessages
  validationVisibility?: Exclude<
    FormValidationVisibility,
    FormValidationVisibility.submit
  >
  validationRules?: FormKitValidationRules
  config?: Record<string, unknown>
  plugins?: FormKitPlugin[]
  classes?: Record<string, string | Record<string, boolean> | FormKitClasses>
  props?: FormFieldAdditionalProps
  outerClass?: Record<string, string | Record<string, boolean> | FormKitClasses>
  wrapperClass?: Record<
    string,
    string | Record<string, boolean> | FormKitClasses
  >
  labelClass?: Record<string, string | Record<string, boolean> | FormKitClasses>
  prefixClass?: Record<
    string,
    string | Record<string, boolean> | FormKitClasses
  >
  innerClass?: Record<string, string | Record<string, boolean> | FormKitClasses>
  suffixClass?: Record<
    string,
    string | Record<string, boolean> | FormKitClasses
  >
  inputClass?: Record<string, string | Record<string, boolean> | FormKitClasses>
  helpClass?: Record<string, string | Record<string, boolean> | FormKitClasses>
  messagesClass?: Record<
    string,
    string | Record<string, boolean> | FormKitClasses
  >
  messageClass?: Record<
    string,
    string | Record<string, boolean> | FormKitClasses
  >
}

export interface FormSchemaGroupOrList {
  type: string
  name: string
  children: FormSchemaField[]
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

export type FormSchemaNode =
  | FormSchemaLayout
  | FormSchemaField
  | FormSchemaGroupOrList

export interface ReactiveFormSchemData {
  fields: Record<
    string,
    {
      show: boolean
      props: Except<FormSchemaField, 'show' | 'props'>
    }
  >
}

export interface FormValues {
  [index: string]: unknown
}

export type FormData<TFormValues = FormValues> = FormKitGroupValue & TFormValues
