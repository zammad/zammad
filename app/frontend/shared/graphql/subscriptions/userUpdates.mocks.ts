import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getUserUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.UserUpdatesSubscription>(Operations.UserUpdatesDocument)
}
