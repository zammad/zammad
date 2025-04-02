import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentOverviewOrderingUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getUserCurrentOverviewOrderingUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.UserCurrentOverviewOrderingUpdatesSubscription>(Operations.UserCurrentOverviewOrderingUpdatesDocument)
}
