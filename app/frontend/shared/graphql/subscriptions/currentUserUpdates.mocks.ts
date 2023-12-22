import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './currentUserUpdates.api.ts'

export function getCurrentUserUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.CurrentUserUpdatesSubscription>(Operations.CurrentUserUpdatesDocument)
}
