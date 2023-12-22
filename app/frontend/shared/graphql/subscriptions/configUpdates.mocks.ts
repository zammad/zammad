import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './configUpdates.api.ts'

export function getConfigUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.ConfigUpdatesSubscription>(Operations.ConfigUpdatesDocument)
}
