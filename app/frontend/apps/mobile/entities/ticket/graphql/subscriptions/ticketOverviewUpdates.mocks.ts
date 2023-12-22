import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketOverviewUpdates.api.ts'

export function getTicketOverviewUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.TicketOverviewUpdatesSubscription>(Operations.TicketOverviewUpdatesDocument)
}
