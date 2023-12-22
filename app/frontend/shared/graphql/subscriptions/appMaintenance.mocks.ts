import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './appMaintenance.api.ts'

export function getAppMaintenanceSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.AppMaintenanceSubscription>(Operations.AppMaintenanceDocument)
}
