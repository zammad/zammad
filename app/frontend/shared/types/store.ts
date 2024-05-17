// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { CurrentUserQuery } from '#shared/graphql/types.ts'

import type { Store } from 'pinia'

export type { ConfigList } from './config.ts'

export interface UsedStore {
  store: Store
  requiresAuth: boolean
}

export type UserData = CurrentUserQuery['currentUser']
