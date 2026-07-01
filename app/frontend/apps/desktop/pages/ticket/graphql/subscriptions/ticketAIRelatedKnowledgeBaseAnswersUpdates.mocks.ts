import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketAIRelatedKnowledgeBaseAnswersUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getTicketAiRelatedKnowledgeBaseAnswersUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.TicketAiRelatedKnowledgeBaseAnswersUpdatesSubscription>(Operations.TicketAiRelatedKnowledgeBaseAnswersUpdatesDocument)
}
