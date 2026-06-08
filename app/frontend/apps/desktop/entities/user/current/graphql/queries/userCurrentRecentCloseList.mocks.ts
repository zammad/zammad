import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentRecentCloseList.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentRecentCloseListQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentRecentCloseListQuery, Types.UserCurrentRecentCloseListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentRecentCloseListDocument, defaults)
}

export function waitForUserCurrentRecentCloseListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentRecentCloseListQuery>(Operations.UserCurrentRecentCloseListDocument)
}

export function mockUserCurrentRecentCloseListQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentRecentCloseListDocument, message, extensions);
}
