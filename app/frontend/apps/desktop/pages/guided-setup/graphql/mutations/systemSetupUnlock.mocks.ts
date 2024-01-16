import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './systemSetupUnlock.api.ts'

export function mockSystemSetupUnlockMutation(defaults: Mocks.MockDefaultsValue<Types.SystemSetupUnlockMutation, Types.SystemSetupUnlockMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.SystemSetupUnlockDocument, defaults)
}

export function waitForSystemSetupUnlockMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.SystemSetupUnlockMutation>(Operations.SystemSetupUnlockDocument)
}
