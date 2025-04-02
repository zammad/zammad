import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTaskbarItemStateUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getUserCurrentTaskbarItemStateUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.UserCurrentTaskbarItemStateUpdatesSubscription>(Operations.UserCurrentTaskbarItemStateUpdatesDocument)
}
