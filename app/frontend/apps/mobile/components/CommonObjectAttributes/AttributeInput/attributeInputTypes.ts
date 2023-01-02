// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectManagerFrontendAttribute } from '@shared/graphql/types'

export interface ObjectAttributeInput extends ObjectManagerFrontendAttribute {
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
