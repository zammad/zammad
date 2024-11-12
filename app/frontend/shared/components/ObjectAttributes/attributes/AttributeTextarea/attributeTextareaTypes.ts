// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'

export interface ObjectAttributeTextarea extends ObjectAttribute {
  dataType: 'textarea'
  dataOption: {
    item_class: string
    maxlength: number
    linktemplate?: string
    null: boolean
  }
}
