import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './knowledgeBaseFeed.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockKnowledgeBaseFeedQuery(defaults: Mocks.MockDefaultsValue<Types.KnowledgeBaseFeedQuery, Types.KnowledgeBaseFeedQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.KnowledgeBaseFeedDocument, defaults)
}

export function waitForKnowledgeBaseFeedQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.KnowledgeBaseFeedQuery>(Operations.KnowledgeBaseFeedDocument)
}

export function mockKnowledgeBaseFeedQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.KnowledgeBaseFeedDocument, message, extensions);
}
