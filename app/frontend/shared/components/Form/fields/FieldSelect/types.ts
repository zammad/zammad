// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { TicketState } from '@shared/entities/ticket/types'
import type { Props as IconProps } from '@shared/components/CommonIcon/CommonIcon.vue'
import type { FormFieldContext } from '../../types/field'

export type SelectValue = string | number | boolean

export interface SelectOption {
  value: SelectValue
  label?: string
  labelPlaceholder?: string[]
  disabled?: boolean
  status?: TicketState
  icon?: string
  iconProps?: Omit<IconProps, 'name'>
}

export type SelectOptionSorting = 'label' | 'value'

export type SelectContext = FormFieldContext<{
  clearable?: boolean
  disabled?: boolean
  historicalOptions: Record<string, string>
  multiple?: boolean
  noOptionsLabelTranslation?: boolean
  options: SelectOption[]
  rejectNonExistentValues?: boolean
  sorting?: SelectOptionSorting
}>
