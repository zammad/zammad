// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { EntityAttribute } from '#shared/entities/core/attributes/types/store.ts'

export interface EntityAttributeTextarea extends EntityAttribute {
  dataType: 'textarea'
  dataOption: {
    item_class: string
    maxlength: number
    linktemplate?: string
    null: boolean
  }
}
