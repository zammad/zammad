import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseAnswerUpdate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseAnswerUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseAnswerUpdateMutation, Types.KnowledgeBaseAnswerUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseAnswerUpdateDocument, defaults)
}

export function waitForKnowledgeBaseAnswerUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseAnswerUpdateMutation>(Operations.KnowledgeBaseAnswerUpdateDocument)
}

export function mockKnowledgeBaseAnswerUpdateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseAnswerUpdateDocument, message, extensions);
}
