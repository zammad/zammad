import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTaskbarItemList.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentTaskbarItemListQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTaskbarItemListQuery, Types.UserCurrentTaskbarItemListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTaskbarItemListDocument, defaults)
}

export function waitForUserCurrentTaskbarItemListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTaskbarItemListQuery>(Operations.UserCurrentTaskbarItemListDocument)
}

export function mockUserCurrentTaskbarItemListQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentTaskbarItemListDocument, message, extensions);
}
