// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { SelectOption } from '#shared/components/CommonSelect/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

import type { SelectOptionSorting } from '../FieldSelect/types.ts'

export type TreeSelectOption = SelectOption & {
  children?: TreeSelectOption[]
}

export type FlatSelectOption = SelectOption & {
  hasChildren: boolean
  parents: (string | number | boolean)[]
}

export type MatchedFlatSelectOption = FlatSelectOption & {
  matchedPath?: string
}

export interface TreeSelectProps {
  clearable?: boolean
  historicalOptions?: Record<string, string>
  multiple?: boolean
  options: TreeSelectOption[]
  noFiltering?: boolean
  noOptionsLabelTranslation?: boolean
  rejectNonExistentValues?: boolean
  sorting?: SelectOptionSorting
}

export type TreeSelectContext = FormFieldContext<TreeSelectProps>
