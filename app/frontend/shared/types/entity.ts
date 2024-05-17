// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectAttributeValue } from '#shared/graphql/types.ts'

import type { PartialDeep } from 'type-fest'

export interface EntityObject {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  [index: string]: any
  objectAttributeValues?: Maybe<Array<PartialDeep<ObjectAttributeValue>>>
}
