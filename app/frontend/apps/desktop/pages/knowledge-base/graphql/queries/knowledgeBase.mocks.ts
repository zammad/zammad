import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBase.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseQuery(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseQuery, Types.KnowledgeBaseQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseDocument, defaults)
}

export function waitForKnowledgeBaseQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseQuery>(Operations.KnowledgeBaseDocument)
}

export function mockKnowledgeBaseQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseDocument, message, extensions);
}
