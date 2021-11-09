import { CurrentUserQuery } from '@common/graphql/types'

// Should be used for a single value store.
export interface DefaultStore<TValue> {
  value: TValue
}

export type UserData = Maybe<CurrentUserQuery['currentUser']>
