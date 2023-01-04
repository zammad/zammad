// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldContext } from '../../types/field'
import type { SelectOption, SelectOptionSorting } from '../FieldSelect'

export type TreeSelectOption = SelectOption & {
  children?: TreeSelectOption[]
}

export type FlatSelectOption = SelectOption & {
  hasChildren: boolean
  parents: (string | number | boolean)[]
}

export type TreeSelectContext = FormFieldContext<{
  clearable?: boolean
  disabled?: boolean
  historicalOptions: Record<string, string>
  multiple?: boolean
  noFiltering?: boolean
  noOptionsLabelTranslation?: boolean
  options: TreeSelectOption[]
  rejectNonExistentValues?: boolean
  sorting?: SelectOptionSorting
}>
