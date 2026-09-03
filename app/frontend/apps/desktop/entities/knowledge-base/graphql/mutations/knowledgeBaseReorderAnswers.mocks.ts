import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseReorderAnswers.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseReorderAnswersMutation(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseReorderAnswersMutation, Types.KnowledgeBaseReorderAnswersMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseReorderAnswersDocument, defaults)
}

export function waitForKnowledgeBaseReorderAnswersMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseReorderAnswersMutation>(Operations.KnowledgeBaseReorderAnswersDocument)
}

export function mockKnowledgeBaseReorderAnswersMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseReorderAnswersDocument, message, extensions);
}
