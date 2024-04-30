import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountDeviceDelete.api.ts'

export function mockAccountDeviceDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.AccountDeviceDeleteMutation, Types.AccountDeviceDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountDeviceDeleteDocument, defaults)
}

export function waitForAccountDeviceDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountDeviceDeleteMutation>(Operations.AccountDeviceDeleteDocument)
}
