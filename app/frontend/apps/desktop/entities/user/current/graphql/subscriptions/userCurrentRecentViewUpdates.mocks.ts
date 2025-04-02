import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentRecentViewUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getUserCurrentRecentViewUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.UserCurrentRecentViewUpdatesSubscription>(Operations.UserCurrentRecentViewUpdatesDocument)
}
