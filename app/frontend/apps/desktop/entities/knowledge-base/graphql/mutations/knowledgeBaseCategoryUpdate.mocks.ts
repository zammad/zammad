import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseCategoryUpdate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseCategoryUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseCategoryUpdateMutation, Types.KnowledgeBaseCategoryUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseCategoryUpdateDocument, defaults)
}

export function waitForKnowledgeBaseCategoryUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseCategoryUpdateMutation>(Operations.KnowledgeBaseCategoryUpdateDocument)
}

export function mockKnowledgeBaseCategoryUpdateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseCategoryUpdateDocument, message, extensions);
}
