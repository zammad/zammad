// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type {
  FormKitClasses,
  FormKitGroupValue,
  FormKitNode,
  FormKitPlugin,
  FormKitSchemaAttributes,
  FormKitSchemaCondition,
  FormKitSchemaNode,
} from '@formkit/core'
import type {
  FormKitValidationMessages,
  FormKitValidationRules,
} from '@formkit/validation'
import type { EnumObjectManagerObjects } from '@shared/graphql/types'
import type { Except, Primitive, SetOptional, SetRequired } from 'type-fest'

export interface FormFieldAdditionalProps {
  belongsToObjectField?: string
  [index: string]: unknown
}

type SimpleFormFieldValue = Primitive | Primitive[]

export type FormFieldValue =
  | SimpleFormFieldValue
  | SimpleFormFieldValue[]
  | Record<string, SimpleFormFieldValue>

// https://formkit.com/essentials/validation#showing-errors
export enum FormValidationVisibility {
  Blur = 'blur',
  Live = 'live',
  Dirty = 'dirty',
  Submit = 'submit',
}

export type AllowedClasses = string | Record<string, boolean> | FormKitClasses

export interface FormSchemaField {
  if?: string
  show?: boolean
  relation?: {
    type: string
    filterIds?: number[]
  }
  updateFields?: boolean
  triggerFormUpdater?: boolean
  type: string
  name: string
  internal?: boolean
  value?: FormFieldValue
  label?: string
  labelPlaceholder?: string
  placeholder?: string
  help?: string
  disabled?: boolean
  required?: boolean
  delay?: number
  errors?: string[]
  hidden?: boolean
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
    FormValidationVisibility.Submit
  >
  validationRules?: FormKitValidationRules
  config?: Record<string, unknown>
  plugins?: FormKitPlugin[]
  classes?: AllowedClasses
  props?: FormFieldAdditionalProps
  outerClass?: AllowedClasses
  wrapperClass?: AllowedClasses
  labelClass?: AllowedClasses
  prefixClass?: AllowedClasses
  innerClass?: AllowedClasses
  suffixClass?: AllowedClasses
  inputClass?: AllowedClasses
  blockClass?: AllowedClasses
  helpClass?: AllowedClasses
  messagesClass?: AllowedClasses
  messageClass?: AllowedClasses
}

export interface FormSchemaGroupOrList {
  isGroupOrList: boolean
  type: 'group' | 'list'
  name: string
  plugins?: FormKitPlugin[]
}

interface FormSchemaLayoutBase {
  isLayout: boolean
  hidden?: string
}

export interface FormSchemaComponent extends FormSchemaLayoutBase {
  if?: string
  component: string
  props?: {
    [index: string]: unknown
  }
}

export interface FormSchemaDOMElement extends FormSchemaLayoutBase {
  if?: string
  element: string
  attrs?: FormKitSchemaAttributes
}

export interface FormSchemaFieldsForObjectAttributeScreen {
  screen: string
  object: EnumObjectManagerObjects
}

export type FormSchemaFieldObjectAttribute = SetRequired<
  Partial<FormSchemaField>,
  'name'
> & {
  screen?: string
  object: EnumObjectManagerObjects
}

export type FormSchemaLayout = FormSchemaComponent | FormSchemaDOMElement

export type FormSchemaNodeWithChildren = (
  | FormSchemaLayout
  | FormSchemaGroupOrList
) & {
  children:
    | (
        | FormSchemaField
        | FormSchemaFieldObjectAttribute
        | FormSchemaFieldsForObjectAttributeScreen
        | FormSchemaNodeWithChildren
        | string
      )[]
    | string
}

export type FormSchemaNode =
  | FormSchemaNodeWithChildren
  | FormSchemaField
  | FormSchemaFieldObjectAttribute
  | FormSchemaFieldsForObjectAttributeScreen
  | string

export interface ReactiveFormSchemData {
  fields: Record<
    string,
    {
      show: boolean
      updateFields: boolean
      props: Except<
        SetOptional<FormSchemaField, 'type'>,
        'show' | 'props' | 'updateFields' | 'relation'
      >
    }
  >
  [index: string]: unknown
}

export interface FormValues {
  [index: string]: FormFieldValue
}

export type FormData<TFormValues = FormValues> = FormKitGroupValue &
  TFormValues & {
    formId: string
  }

export interface ChangedField {
  name: string
  newValue: FormFieldValue
  oldValue: FormFieldValue
}

export enum FormHandlerExecution {
  Initial = 'initial',
  FieldChange = 'fieldChange',
}

export type FormHandlerFunction = (
  execution: FormHandlerExecution,
  formNode: FormKitNode | undefined,
  values: FormValues,
  changeFields: Record<string, Partial<FormSchemaField>>,
  updateSchemaDataField: (
    field: FormSchemaField | SetRequired<Partial<FormSchemaField>, 'name'>,
  ) => void,
  schemaData: ReactiveFormSchemData,
  changedField?: ChangedField,
) => void

export interface FormHandler {
  execution: FormHandlerExecution[]
  callback: FormHandlerFunction
}
