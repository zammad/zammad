// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectManagerFrontendAttribute } from '@shared/graphql/types'

export interface ObjectAttributeTextarea
  extends ObjectManagerFrontendAttribute {
  dataType: 'textarea'
  dataOption: {
    item_class: string
    maxlength: number
    linktemplate?: string
    null: boolean
  }
}
