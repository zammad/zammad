import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTaskbarItemListUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getUserCurrentTaskbarItemListUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.UserCurrentTaskbarItemListUpdatesSubscription>(Operations.UserCurrentTaskbarItemListUpdatesDocument)
}
