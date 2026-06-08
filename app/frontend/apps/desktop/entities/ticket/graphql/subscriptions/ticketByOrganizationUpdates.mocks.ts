import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketByOrganizationUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getTicketByOrganizationUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.TicketByOrganizationUpdatesSubscription>(Operations.TicketByOrganizationUpdatesDocument)
}
