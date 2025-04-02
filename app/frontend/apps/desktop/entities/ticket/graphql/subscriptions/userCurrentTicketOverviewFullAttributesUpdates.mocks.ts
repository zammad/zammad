import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTicketOverviewFullAttributesUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getUserCurrentTicketOverviewFullAttributesUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.UserCurrentTicketOverviewFullAttributesUpdatesSubscription>(Operations.UserCurrentTicketOverviewFullAttributesUpdatesDocument)
}
