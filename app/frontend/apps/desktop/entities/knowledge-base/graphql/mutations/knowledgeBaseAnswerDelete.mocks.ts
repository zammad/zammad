import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseAnswerDelete.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseAnswerDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseAnswerDeleteMutation, Types.KnowledgeBaseAnswerDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseAnswerDeleteDocument, defaults)
}

export function waitForKnowledgeBaseAnswerDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseAnswerDeleteMutation>(Operations.KnowledgeBaseAnswerDeleteDocument)
}

export function mockKnowledgeBaseAnswerDeleteMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseAnswerDeleteDocument, message, extensions);
}
