import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentAvatarUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getUserCurrentAvatarUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.UserCurrentAvatarUpdatesSubscription>(Operations.UserCurrentAvatarUpdatesDocument)
}
