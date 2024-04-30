import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountDeviceList.api.ts'

export function mockAccountDeviceListQuery(defaults: Mocks.MockDefaultsValue<Types.AccountDeviceListQuery, Types.AccountDeviceListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountDeviceListDocument, defaults)
}

export function waitForAccountDeviceListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountDeviceListQuery>(Operations.AccountDeviceListDocument)
}
