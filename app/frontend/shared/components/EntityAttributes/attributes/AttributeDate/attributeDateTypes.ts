// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { EntityAttribute } from '#shared/entities/core/attributes/types/store.ts'

export interface EntityAttributeDate extends EntityAttribute {
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
