import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTaskbarItemList.api.ts'

export function mockUserCurrentTaskbarItemListQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTaskbarItemListQuery, Types.UserCurrentTaskbarItemListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTaskbarItemListDocument, defaults)
}

export function waitForUserCurrentTaskbarItemListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTaskbarItemListQuery>(Operations.UserCurrentTaskbarItemListDocument)
}
