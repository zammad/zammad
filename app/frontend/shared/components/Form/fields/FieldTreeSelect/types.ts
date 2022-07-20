// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldContext } from '../../types/field'
import type { SelectOption, SelectOptionSorting } from '../FieldSelect'

export type TreeSelectOption = SelectOption & {
  children?: TreeSelectOption[]
}

export type FlatSelectOption = SelectOption & {
  hasChildren: boolean
  parents: (string | number)[]
}

export type TreeSelectContext = FormFieldContext<{
  autoselect?: boolean
  clearable?: boolean
  noFiltering?: boolean
  disabled?: boolean
  multiple?: boolean
  noOptionsLabelTranslation?: boolean
  options: TreeSelectOption[]
  sorting?: SelectOptionSorting
}>
