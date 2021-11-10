// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { CurrentUserQuery } from '@common/graphql/types'

// Should be used for a single value store.
export interface DefaultStore<TValue> {
  value: TValue
}

export type UserData = Maybe<CurrentUserQuery['currentUser']>
