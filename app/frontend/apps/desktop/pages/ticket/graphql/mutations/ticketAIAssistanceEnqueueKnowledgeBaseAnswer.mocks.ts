import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketAIAssistanceEnqueueKnowledgeBaseAnswer.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation(defaults: Mocks.MockDefaultsValue<Types.TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation, Types.TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketAiAssistanceEnqueueKnowledgeBaseAnswerDocument, defaults)
}

export function waitForTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation>(Operations.TicketAiAssistanceEnqueueKnowledgeBaseAnswerDocument)
}

export function mockTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketAiAssistanceEnqueueKnowledgeBaseAnswerDocument, message, extensions);
}
