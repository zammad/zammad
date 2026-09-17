import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketArticleTranslationUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getTicketArticleTranslationUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.TicketArticleTranslationUpdatesSubscription>(Operations.TicketArticleTranslationUpdatesDocument)
}
