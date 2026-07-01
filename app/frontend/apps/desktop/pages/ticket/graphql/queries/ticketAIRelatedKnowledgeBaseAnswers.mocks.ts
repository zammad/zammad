import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketAIRelatedKnowledgeBaseAnswers.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketAiRelatedKnowledgeBaseAnswersQuery(defaults: Mocks.MockDefaultsValue<Types.TicketAiRelatedKnowledgeBaseAnswersQuery, Types.TicketAiRelatedKnowledgeBaseAnswersQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketAiRelatedKnowledgeBaseAnswersDocument, defaults)
}

export function waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketAiRelatedKnowledgeBaseAnswersQuery>(Operations.TicketAiRelatedKnowledgeBaseAnswersDocument)
}

export function mockTicketAiRelatedKnowledgeBaseAnswersQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketAiRelatedKnowledgeBaseAnswersDocument, message, extensions);
}
