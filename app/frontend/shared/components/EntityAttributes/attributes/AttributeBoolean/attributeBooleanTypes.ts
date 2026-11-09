// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { EntityAttribute } from '#shared/entities/core/attributes/types/store.ts'

export interface EntityAttributeBoolean extends EntityAttribute {
  dataType: 'boolean'
  dataOption: {
    default: boolean
    item_class: string
    note: string
    null: boolean
    options: { true: string; false: string }
    permission: string[]
    translate: boolean
  }
}
