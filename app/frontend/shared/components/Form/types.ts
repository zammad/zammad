// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { Sizes } from '#shared/components/CommonIcon/types.ts'
import type {
  EnumObjectManagerObjects,
  FormUpdaterQuery,
} from '#shared/graphql/types.ts'
import type { EntityObject } from '#shared/types/entity.ts'
import type { FormUpdaterOptions } from '#shared/types/form.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

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
import type { Except, Primitive, SetOptional, SetRequired } from 'type-fest'
import type { Ref, ShallowRef } from 'vue'

export interface FormFieldAdditionalProps {
  belongsToObjectField?: string

  [index: string]: unknown
}

type SimpleFormFieldValueBase =
  | Primitive
  | Primitive[]
  | Record<string, Primitive | Primitive[]>

type SimpleFormFieldValue =
  | SimpleFormFieldValueBase
  | Record<string, SimpleFormFieldValueBase>

export type FormFieldValue =
  | SimpleFormFieldValue
  | SimpleFormFieldValue[]
  | Record<string, SimpleFormFieldValue>
  | Record<string, SimpleFormFieldValue>[]

export interface FormValues {
  [index: string]: FormFieldValue
}

export type FormSubmitData<TFormValues = FormValues> = FormKitGroupValue &
  TFormValues

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
  pendingValueUpdate?: boolean
  type: string
  name: string
  internal?: boolean
  value?: FormFieldValue
  initialValue?: FormFieldValue
  label?: string
  labelSrOnly?: boolean
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
  fieldsetClass?: AllowedClasses
  messagesClass?: AllowedClasses
  messageClass?: AllowedClasses
}

export interface FormSchemaGroupOrList {
  if?: string
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
    | FormKitSchemaCondition
}

export type FormSchemaNode =
  | FormSchemaNodeWithChildren
  | FormSchemaField
  | FormSchemaFieldObjectAttribute
  | FormSchemaFieldsForObjectAttributeScreen
  | string

export interface ReactiveFormSchemaDataField {
  show: boolean
  staticCondition: boolean
  updateFields: boolean
  props: Except<
    SetOptional<FormSchemaField, 'type'>,
    'show' | 'props' | 'updateFields' | 'relation'
  >
}

export interface ReactiveFormSchemData {
  fields: Record<string, ReactiveFormSchemaDataField>
  flags: Record<string, boolean>

  [index: string]: unknown
}

export interface ChangedField {
  name: string
  newValue: FormFieldValue
  oldValue: FormFieldValue
}

export type ChangedFieldFunction = {
  (
    name: string,
    callback: (
      newValue: FormFieldValue,
      oldValue: FormFieldValue,
      node: FormKitNode,
    ) => void,
  ): void
}

export enum FormHandlerExecution {
  Initial = 'initial',
  InitialSettled = 'initialSettled',
  FieldChange = 'fieldChange',
}

export interface FormHandlerFunctionData {
  formNode: FormKitNode | undefined

  getNodeByName(id: string): FormKitNode | undefined

  findNodeByName(name: string): FormKitNode | undefined

  values: FormValues
  changedField?: ChangedField
  initialEntityObject?: ObjectLike

  formUpdaterData?: FormUpdaterQuery['formUpdater']
}

type UpdateSchemaDataFieldFunction = (
  field: FormSchemaField | SetRequired<Partial<FormSchemaField>, 'name'>,
) => void

export interface FormHandlerFunctionReactivity {
  changeFields: Ref<Record<string, Partial<FormSchemaField>>>
  schemaData: ReactiveFormSchemData
  // This can be used to update the current schema data, but without remembering it inside
  // the changeFields and schemaData objects (which means it's persistent).
  updateSchemaDataField: UpdateSchemaDataFieldFunction
}

export type FormHandlerFunction = (
  execution: FormHandlerExecution,
  reactivity: FormHandlerFunctionReactivity,
  data: FormHandlerFunctionData,
) => void

export interface FormHandler {
  execution: FormHandlerExecution[]
  callback: FormHandlerFunction
}

// With this it's possible to add an own reset handling to the form submit
// and also an finally function after the reset.
// A use case is when you have two groups inside a form but one group is not available
// when you start with the from (e.g. article in ticket context). With the normal reset
// the default initial values will be set with the two groups (when both are active during the submit).
export interface FormOnSubmitFunctionCallbacks {
  reset?: (values: FormSubmitData, nodeValues: FormValues) => void
  finally?: () => void
}

export interface FormResetData {
  values?: FormValues
  object?: EntityObject
}

export interface FormResetOptions {
  /**
   * Should reset dirty fields to new values.
   * @default true
   */
  resetDirty?: boolean
  /**
   * Should reset flags to false.
   * @default true
   */
  resetFlags?: boolean
  groupNode?: FormKitNode
}

export interface FormRef {
  formId: string
  formNode: FormKitNode
  formInitialSettled: boolean
  values: FormValues
  flags: Record<string, boolean>
  updateSchemaDataField: UpdateSchemaDataFieldFunction
  updateChangedFields: (
    changedFields: Record<string, Partial<FormSchemaField>>,
  ) => void

  getNodeByName(id: string): FormKitNode | undefined

  findNodeByName(name: string): FormKitNode | undefined

  resetForm(data?: FormResetData, options?: FormResetOptions): void

  triggerFormUpdater(options?: FormUpdaterOptions): void
}

export type FormRefParameter = ShallowRef<FormRef | undefined>

export interface FormStep {
  label: string
  order: number
  errorCount: number
  valid: boolean
  disabled: boolean
  completed: boolean
}

export type FormClass = 'loading'
export type FormClassMap = Record<FormClass, string>

export type FormGroupClass = 'container' | 'help' | 'dirtyMark' | 'bottomMargin'
export type FormGroupClassMap = Record<FormGroupClass, string>

export type FieldLinkClass = 'container' | 'base' | 'link'
export type FieldLinkClassMap = Record<FieldLinkClass, string>

export type FieldEditorClass = {
  actionBar: {
    buttonContainer: string
    tableMenuContainer: string
    leftGradient: {
      left: string
      before: {
        background: {
          light: string
          dark: string
        }
      }
    }
    rightGradient: {
      before: {
        background: {
          light: string
          dark: string
        }
      }
    }
    shadowGradient: {
      before: {
        top: string
        height: string
      }
    }
    button: {
      base: string
      active: string
      action?: Record<string, string>
    }
  }
  input: {
    container: string
  }
}

export type FieldEditorProps = {
  actionBar: {
    visible?: boolean
    button: {
      icon: {
        size: Sizes
      }
    }
  }
}
