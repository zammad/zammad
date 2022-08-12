// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { TicketState } from '@shared/entities/ticket/types'
import type { Props as IconProps } from '@shared/components/CommonIcon/CommonIcon.vue'
import type { FormFieldContext } from '../../types/field'

export interface SelectOption {
  value: string | number
  label?: string
  labelPlaceholder?: string[]
  disabled?: boolean
  status?: TicketState
  icon?: string
  iconProps?: Omit<IconProps, 'name'>
}

export type SelectOptionSorting = 'label' | 'value'

export type SelectSize = 'small' | 'medium'

export type SelectContext = FormFieldContext<{
  autoselect?: boolean
  clearable?: boolean
  disabled?: boolean
  multiple?: boolean
  noOptionsLabelTranslation?: boolean
  options: SelectOption[]
  size?: SelectSize
  sorting?: SelectOptionSorting
}>
