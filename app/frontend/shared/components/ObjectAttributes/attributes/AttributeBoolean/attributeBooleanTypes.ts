// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectManagerFrontendAttribute } from '@shared/graphql/types'

export interface ObjectAttributeBoolean extends ObjectManagerFrontendAttribute {
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
