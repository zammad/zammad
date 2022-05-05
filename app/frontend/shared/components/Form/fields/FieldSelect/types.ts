// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { TicketState } from '@shared/entities/ticket/types'

export type SelectOption = {
  value: string | number
  label: string
  labelPlaceholder?: string[]
  disabled?: boolean
  status?: TicketState
  icon?: string
}

export type SelectOptionSorting = 'label' | 'value'

export type SelectSize = 'small' | 'medium'
