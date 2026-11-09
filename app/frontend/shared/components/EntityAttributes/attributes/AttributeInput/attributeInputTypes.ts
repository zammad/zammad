// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { EntityAttribute } from '#shared/entities/core/attributes/types/store.ts'

export interface EntityAttributeInput extends EntityAttribute {
  dataType: 'input'
  dataOption: {
    item_class: string
    maxlength: number
    autocapitalize?: boolean
    null: boolean
    type: 'text' | 'url' | 'email' | 'tel'
    linktemplate?: string
    note?: string
  }
}
