import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketBulkUpdateStatusUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getUserCurrentTicketBulkUpdateStatusUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.UserCurrentTicketBulkUpdateStatusUpdatesSubscription>(Operations.UserCurrentTicketBulkUpdateStatusUpdatesDocument)
}
