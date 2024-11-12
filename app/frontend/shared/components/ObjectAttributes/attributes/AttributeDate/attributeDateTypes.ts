// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'

export interface ObjectAttributeDate extends ObjectAttribute {
  dataType: 'date' | 'datetime'
  dataOption: {
    relation: string
    null: boolean
    past?: boolean
    future?: boolean
    include_timezone?: boolean
    default: Maybe<string>
    diff: Maybe<number>
  }
}
