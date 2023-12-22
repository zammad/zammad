import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketUpdates.api.ts'

export function getTicketUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.TicketUpdatesSubscription>(Operations.TicketUpdatesDocument)
}
