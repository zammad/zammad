import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './systemSetupLock.api.ts'

export function mockSystemSetupLockMutation(defaults: Mocks.MockDefaultsValue<Types.SystemSetupLockMutation, Types.SystemSetupLockMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.SystemSetupLockDocument, defaults)
}

export function waitForSystemSetupLockMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.SystemSetupLockMutation>(Operations.SystemSetupLockDocument)
}
