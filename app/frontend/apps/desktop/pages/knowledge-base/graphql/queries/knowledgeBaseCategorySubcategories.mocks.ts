import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseCategorySubcategories.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseCategorySubcategoriesQuery(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseCategorySubcategoriesQuery, Types.KnowledgeBaseCategorySubcategoriesQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseCategorySubcategoriesDocument, defaults)
}

export function waitForKnowledgeBaseCategorySubcategoriesQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseCategorySubcategoriesQuery>(Operations.KnowledgeBaseCategorySubcategoriesDocument)
}

export function mockKnowledgeBaseCategorySubcategoriesQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseCategorySubcategoriesDocument, message, extensions);
}
