import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketLiveUserUpdates.api.ts'

export function getTicketLiveUserUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.TicketLiveUserUpdatesSubscription>(Operations.TicketLiveUserUpdatesDocument)
}
