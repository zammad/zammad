import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseReorderCategories.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseReorderCategoriesMutation(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseReorderCategoriesMutation, Types.KnowledgeBaseReorderCategoriesMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseReorderCategoriesDocument, defaults)
}

export function waitForKnowledgeBaseReorderCategoriesMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseReorderCategoriesMutation>(Operations.KnowledgeBaseReorderCategoriesDocument)
}

export function mockKnowledgeBaseReorderCategoriesMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseReorderCategoriesDocument, message, extensions);
}
