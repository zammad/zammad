// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import type { SelectOption } from '#shared/components/CommonSelect/types.ts'

export type SelectOptionSorting = 'label' | 'value'

export type SelectContext = FormFieldContext<{
  clearable?: boolean
  disabled?: boolean
  historicalOptions: Record<string, string>
  multiple?: boolean
  noOptionsLabelTranslation?: boolean
  options: SelectOption[]
  rejectNonExistentValues?: boolean
  pendingValueUpdate?: boolean
  sorting?: SelectOptionSorting
}>
