// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { CurrentUserQuery } from '@common/graphql/types'
import type { Primitive } from 'type-fest'

export interface SingleValueStore<TValue> {
  value: TValue
}

export type UserData = Maybe<CurrentUserQuery['currentUser']>

export type ConfigValues =
  | Primitive
  | Record<string, Primitive>
  | Array<Primitive | Record<string, Primitive>>
