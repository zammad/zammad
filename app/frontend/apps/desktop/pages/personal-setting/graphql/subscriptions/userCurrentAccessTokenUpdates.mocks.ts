import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentAccessTokenUpdates.api.ts'

export function getUserCurrentAccessTokenUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.UserCurrentAccessTokenUpdatesSubscription>(Operations.UserCurrentAccessTokenUpdatesDocument)
}
