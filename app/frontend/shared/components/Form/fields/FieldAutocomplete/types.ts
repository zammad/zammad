// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ConcreteComponent } from 'vue'
import type { RouteLocationRaw } from 'vue-router'
import type { JsonValue } from 'type-fest'
import type { DocumentNode } from 'graphql'
import type { ObjectLike } from '#shared/types/utils.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import type { SelectOptionSorting } from '../FieldSelect/types.ts'

export type AutoCompleteOption = {
  value: string | number
  label: string
  labelPlaceholder?: string[]
  heading?: string
  headingPlaceholder?: string[]
  disabled?: boolean
  icon?: string
}

export type AutoCompleteProps = FormFieldContext<{
  gqlQuery: DocumentNode
  action?: RouteLocationRaw
  actionIcon?: string
  actionLabel?: string
  allowUnknownValues?: boolean
  clearable?: boolean
  debounceInterval: number
  disabled?: boolean
  defaultFilter?: string
  filterInputPlaceholder?: string
  filterInputValidation?: string
  limit?: number
  multiple?: boolean
  noOptionsLabelTranslation?: boolean
  optionIconComponent?: ConcreteComponent
  options?: AutoCompleteOption[]
  belongsToObjectField?: string
  additionalQueryParams?: Record<string, JsonValue>
  dialogNotFoundMessage?: string
  dialogEmptyMessage?: string
  initialOptionBuilder?: (
    initialEntityObject: ObjectLike,
    value: SelectValue,
    context?: FormFieldContext,
  ) => AutoCompleteOption
  sorting?: SelectOptionSorting
  onActionClick?: () => void
}>
