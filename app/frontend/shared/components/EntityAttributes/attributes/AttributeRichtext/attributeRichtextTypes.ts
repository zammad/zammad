// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { EntityAttribute } from '#shared/entities/core/attributes/types/store.ts'

export interface EntityAttributeRichtext extends EntityAttribute {
  dataType: 'richtext'
  dataOption: {
    maxlength: number
    no_images: boolean
    note: string
    null: boolean
    upload?: boolean
    rows?: number
    type: string // text
  }
}
