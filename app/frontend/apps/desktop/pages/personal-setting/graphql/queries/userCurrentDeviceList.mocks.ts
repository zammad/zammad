import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentDeviceList.api.ts'

export function mockUserCurrentDeviceListQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentDeviceListQuery, Types.UserCurrentDeviceListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentDeviceListDocument, defaults)
}

export function waitForUserCurrentDeviceListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentDeviceListQuery>(Operations.UserCurrentDeviceListDocument)
}
