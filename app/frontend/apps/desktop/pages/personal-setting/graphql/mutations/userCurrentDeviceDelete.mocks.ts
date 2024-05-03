import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentDeviceDelete.api.ts'

export function mockUserCurrentDeviceDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentDeviceDeleteMutation, Types.UserCurrentDeviceDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentDeviceDeleteDocument, defaults)
}

export function waitForUserCurrentDeviceDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentDeviceDeleteMutation>(Operations.UserCurrentDeviceDeleteDocument)
}
