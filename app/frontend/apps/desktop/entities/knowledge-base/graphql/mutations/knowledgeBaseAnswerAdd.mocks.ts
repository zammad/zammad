import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseAnswerAdd.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseAnswerAddMutation(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseAnswerAddMutation, Types.KnowledgeBaseAnswerAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseAnswerAddDocument, defaults)
}

export function waitForKnowledgeBaseAnswerAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseAnswerAddMutation>(Operations.KnowledgeBaseAnswerAddDocument)
}

export function mockKnowledgeBaseAnswerAddMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseAnswerAddDocument, message, extensions);
}
