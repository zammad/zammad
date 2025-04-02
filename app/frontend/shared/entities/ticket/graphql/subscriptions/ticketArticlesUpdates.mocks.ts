import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketArticlesUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getTicketArticleUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.TicketArticleUpdatesSubscription>(Operations.TicketArticleUpdatesDocument)
}
