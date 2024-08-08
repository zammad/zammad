import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketChecklistUpdates.api.ts'

export function getTicketChecklistUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.TicketChecklistUpdatesSubscription>(Operations.TicketChecklistUpdatesDocument)
}
