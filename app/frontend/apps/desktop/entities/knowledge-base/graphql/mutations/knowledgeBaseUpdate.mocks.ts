import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseUpdate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseUpdateMutation, Types.KnowledgeBaseUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseUpdateDocument, defaults)
}

export function waitForKnowledgeBaseUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseUpdateMutation>(Operations.KnowledgeBaseUpdateDocument)
}

export function mockKnowledgeBaseUpdateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseUpdateDocument, message, extensions);
}
