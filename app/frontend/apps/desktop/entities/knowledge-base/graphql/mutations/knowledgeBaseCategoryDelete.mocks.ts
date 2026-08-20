import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseCategoryDelete.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseCategoryDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseCategoryDeleteMutation, Types.KnowledgeBaseCategoryDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseCategoryDeleteDocument, defaults)
}

export function waitForKnowledgeBaseCategoryDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseCategoryDeleteMutation>(Operations.KnowledgeBaseCategoryDeleteDocument)
}

export function mockKnowledgeBaseCategoryDeleteMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseCategoryDeleteDocument, message, extensions);
}
