import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseReorderRootCategories.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseReorderRootCategoriesMutation(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseReorderRootCategoriesMutation, Types.KnowledgeBaseReorderRootCategoriesMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseReorderRootCategoriesDocument, defaults)
}

export function waitForKnowledgeBaseReorderRootCategoriesMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseReorderRootCategoriesMutation>(Operations.KnowledgeBaseReorderRootCategoriesDocument)
}

export function mockKnowledgeBaseReorderRootCategoriesMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseReorderRootCategoriesDocument, message, extensions);
}
