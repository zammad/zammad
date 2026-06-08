// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'

export interface ObjectAttributeTimeUnit extends ObjectAttribute {
  dataType: 'time_unit'
}
