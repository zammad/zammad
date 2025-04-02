import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './detailSearch.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockDetailSearchQuery(defaults: Mocks.MockDefaultsValue<Types.DetailSearchQuery, Types.DetailSearchQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.DetailSearchDocument, defaults)
}

export function waitForDetailSearchQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.DetailSearchQuery>(Operations.DetailSearchDocument)
}

export function mockDetailSearchQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.DetailSearchDocument, message, extensions);
}
