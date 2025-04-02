import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './searchCounts.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockSearchCountsQuery(defaults: Mocks.MockDefaultsValue<Types.SearchCountsQuery, Types.SearchCountsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.SearchCountsDocument, defaults)
}

export function waitForSearchCountsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.SearchCountsQuery>(Operations.SearchCountsDocument)
}

export function mockSearchCountsQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.SearchCountsDocument, message, extensions);
}
