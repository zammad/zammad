import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentRecentViewList.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentRecentViewListQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentRecentViewListQuery, Types.UserCurrentRecentViewListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentRecentViewListDocument, defaults)
}

export function waitForUserCurrentRecentViewListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentRecentViewListQuery>(Operations.UserCurrentRecentViewListDocument)
}

export function mockUserCurrentRecentViewListQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentRecentViewListDocument, message, extensions);
}
