// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { CurrentUserQuery } from '@common/graphql/types'

export interface SingleValueStore<TValue> {
  value: TValue
}

export type UserData = Maybe<CurrentUserQuery['currentUser']>
