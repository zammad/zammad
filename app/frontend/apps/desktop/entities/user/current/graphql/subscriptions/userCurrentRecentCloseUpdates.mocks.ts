import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentRecentCloseUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getUserCurrentRecentCloseUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.UserCurrentRecentCloseUpdatesSubscription>(Operations.UserCurrentRecentCloseUpdatesDocument)
}
