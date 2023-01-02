// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectManagerFrontendAttribute } from '@shared/graphql/types'

export interface ObjectAttributeMultiSelect
  extends ObjectManagerFrontendAttribute {
  dataType: 'multiselect' | 'multi_tree_select'
  dataOption: {
    historical_options?: Record<string, string>
    linktemplate: string
    maxlength: number
    null: boolean
    nulloption: boolean
    translate?: boolean
    relation: string
    // array for multi_tree_select
    // irrelevant for displaying
    options: Record<string, string> | Record<string, string>[]
  }
}
