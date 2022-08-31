// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectManagerFrontendAttribute } from '@shared/graphql/types'

export interface ObjectAttributeDate extends ObjectManagerFrontendAttribute {
  dataType: 'date' | 'datetime'
  dataOption: {
    relation: string
    null: boolean
    default: Maybe<string>
    diff: Maybe<string>
  }
}
