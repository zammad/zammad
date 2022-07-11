// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { ConcreteComponent } from 'vue'
import type { RouteLocationRaw } from 'vue-router'
import type { FormFieldContext } from '../../types/field'
import type { SelectOptionSorting } from '../FieldSelect'

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
  action?: RouteLocationRaw
  actionIcon?: string
  autoselect?: boolean
  clearable?: boolean
  debounceInterval: number
  disabled?: boolean
  limit?: number
  multiple?: boolean
  noOptionsLabelTranslation?: boolean
  optionIconComponent?: ConcreteComponent
  options?: AutoCompleteOption[]
  sorting?: SelectOptionSorting
}>
