import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketSharedDraftStartUpdateByGroup.api.ts'

export function getTicketSharedDraftStartUpdateByGroupSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.TicketSharedDraftStartUpdateByGroupSubscription>(Operations.TicketSharedDraftStartUpdateByGroupDocument)
}
