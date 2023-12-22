import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './organizationUpdates.api.ts'

export function getOrganizationUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.OrganizationUpdatesSubscription>(Operations.OrganizationUpdatesDocument)
}
