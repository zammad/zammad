// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { CurrentUserQuery } from '@common/graphql/types'
import type { Primitive } from 'type-fest'

export type ConfigValues =
  | Primitive
  | Record<string, Primitive>
  | Array<Primitive | Record<string, Primitive>>

export type ConfigList = Record<string, ConfigValues>

export type UserData = CurrentUserQuery['currentUser']
