import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketByCustomerUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getTicketByCustomerUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.TicketByCustomerUpdatesSubscription>(Operations.TicketByCustomerUpdatesDocument)
}
