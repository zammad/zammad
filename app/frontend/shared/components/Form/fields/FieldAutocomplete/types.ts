// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import type { SelectOptionSorting } from '../FieldSelect/types.ts'
import type { DocumentNode } from 'graphql'
import type { JsonValue } from 'type-fest'
import type { ConcreteComponent } from 'vue'
import type { RouteLocationRaw } from 'vue-router'

export type AutocompleteSelectValue =
  | SelectValue
  | { value: SelectValue; label: string }

export type AutoCompleteOption = {
  value: string | number
  label: string
  labelPlaceholder?: string[]
  heading?: string
  headingPlaceholder?: string[]
  disabled?: boolean
  icon?: string
  match?: RegExpExecArray
  children?: AutoCompleteOption[]
}

export type AutoCompleteProps = FormFieldContext<{
  gqlQuery: DocumentNode
  action?: RouteLocationRaw
  alternativeBackground?: boolean
  actionIcon?: string
  actionLabel?: string
  allowUnknownValues?: boolean
  clearable?: boolean
  debounceInterval: number
  defaultFilter?: string
  filterInputPlaceholder?: string
  filterInputValidation?: string
  limit?: number
  multiple?: boolean
  noOptionsLabelTranslation?: boolean
  optionIconComponent?: ConcreteComponent
  options?: AutoCompleteOption[]
  belongsToObjectField?: string
  additionalQueryParams?:
    | Record<string, JsonValue>
    | (() => Record<string, JsonValue>)
  dialogNotFoundMessage?: string
  dialogEmptyMessage?: string
  initialOptionBuilder?: (
    initialEntityObject: ObjectLike,
    value: AutocompleteSelectValue,
    context?: FormFieldContext,
  ) => AutoCompleteOption
  autocompleteOptionsPreprocessor?: (
    autocompleteOptions: AutoCompleteOption[],
  ) => AutoCompleteOption[]
  sorting?: SelectOptionSorting
  onActionClick?: () => void
  emptyInitialLabelText?: string
}>
