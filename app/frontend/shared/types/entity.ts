// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectAttributeValue } from '#shared/graphql/types.ts'

import type { PartialDeep } from 'type-fest'

export interface EntityObject {
  // oxlint-disable-next-line no-explicit-any
  [index: string]: any
  objectAttributeValues?: Maybe<Array<PartialDeep<ObjectAttributeValue>>>
}
