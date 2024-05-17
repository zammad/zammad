// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { SelectOption } from '#shared/components/CommonSelect/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

export type SelectOptionSorting = 'label' | 'value'

export type SelectContext = FormFieldContext<{
  clearable?: boolean
  historicalOptions: Record<string, string>
  multiple?: boolean
  noFiltering?: boolean
  noOptionsLabelTranslation?: boolean
  options: SelectOption[]
  rejectNonExistentValues?: boolean
  pendingValueUpdate?: boolean
  sorting?: SelectOptionSorting
}>
