import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseAnswerLiveUserUpdates.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function getKnowledgeBaseAnswerLiveUserUpdatesSubscriptionHandler() {
  return Mocks.getGraphQLSubscriptionHandler<Types.KnowledgeBaseAnswerLiveUserUpdatesSubscription>(Operations.KnowledgeBaseAnswerLiveUserUpdatesDocument)
}
