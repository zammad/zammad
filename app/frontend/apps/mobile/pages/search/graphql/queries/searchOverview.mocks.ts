import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './searchOverview.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockSearchQuery(defaults: Mocks.MockDefaultsValue<Types.SearchQuery, Types.SearchQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.SearchDocument, defaults)
}

export function waitForSearchQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.SearchQuery>(Operations.SearchDocument)
}

export function mockSearchQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.SearchDocument, message, extensions);
}
