import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountDevicesUpdates.api.ts'

export function getAccountDevicesUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.AccountDevicesUpdatesSubscription>(Operations.AccountDevicesUpdatesDocument)
}
