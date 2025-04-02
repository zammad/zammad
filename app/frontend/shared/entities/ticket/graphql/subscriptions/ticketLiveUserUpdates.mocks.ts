import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketLiveUserUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getTicketLiveUserUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.TicketLiveUserUpdatesSubscription>(Operations.TicketLiveUserUpdatesDocument)
}
