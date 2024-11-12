// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'

export interface ObjectAttributeBoolean extends ObjectAttribute {
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
