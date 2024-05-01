import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTwoFactorUpdates.api.ts'

export function getUserCurrentTwoFactorUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.UserCurrentTwoFactorUpdatesSubscription>(Operations.UserCurrentTwoFactorUpdatesDocument)
}
