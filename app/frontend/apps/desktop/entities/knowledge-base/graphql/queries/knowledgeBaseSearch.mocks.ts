import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseSearch.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseSearchQuery(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseSearchQuery, Types.KnowledgeBaseSearchQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseSearchDocument, defaults)
}

export function waitForKnowledgeBaseSearchQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseSearchQuery>(Operations.KnowledgeBaseSearchDocument)
}

export function mockKnowledgeBaseSearchQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseSearchDocument, message, extensions);
}
