import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseCategoryAdd.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseCategoryAddMutation(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseCategoryAddMutation, Types.KnowledgeBaseCategoryAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseCategoryAddDocument, defaults)
}

export function waitForKnowledgeBaseCategoryAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseCategoryAddMutation>(Operations.KnowledgeBaseCategoryAddDocument)
}

export function mockKnowledgeBaseCategoryAddMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseCategoryAddDocument, message, extensions);
}
