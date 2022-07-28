// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { CurrentUserQuery } from '@shared/graphql/types'
import type { JsonPrimitive } from 'type-fest'

export type ConfigValues =
  | JsonPrimitive
  | Record<string, JsonPrimitive>
  | Array<JsonPrimitive | Record<string, JsonPrimitive>>

export type ConfigList = Record<string, ConfigValues>

export type UserData = CurrentUserQuery['currentUser']
