import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTaskbarItemUpdates.api.ts'

export function getUserCurrentTaskbarItemUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.UserCurrentTaskbarItemUpdatesSubscription>(Operations.UserCurrentTaskbarItemUpdatesDocument)
}
