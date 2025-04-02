import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './systemSetupUnlock.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockSystemSetupUnlockMutation(defaults: Mocks.MockDefaultsValue<Types.SystemSetupUnlockMutation, Types.SystemSetupUnlockMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.SystemSetupUnlockDocument, defaults)
}

export function waitForSystemSetupUnlockMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.SystemSetupUnlockMutation>(Operations.SystemSetupUnlockDocument)
}

export function mockSystemSetupUnlockMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.SystemSetupUnlockDocument, message, extensions);
}
