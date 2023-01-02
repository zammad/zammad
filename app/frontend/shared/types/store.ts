// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { CurrentUserQuery } from '@shared/graphql/types'
import type { Store } from 'pinia'
import type { JsonPrimitive } from 'type-fest'

export interface UsedStore {
  store: Store
  requiresAuth: boolean
}

export type ConfigValues =
  | JsonPrimitive
  | Record<string, JsonPrimitive>
  | Array<JsonPrimitive | Record<string, JsonPrimitive>>

export type ConfigList = Record<string, ConfigValues>

export type UserData = CurrentUserQuery['currentUser']
