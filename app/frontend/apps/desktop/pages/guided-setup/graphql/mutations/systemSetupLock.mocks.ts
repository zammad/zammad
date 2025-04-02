import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './systemSetupLock.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockSystemSetupLockMutation(defaults: Mocks.MockDefaultsValue<Types.SystemSetupLockMutation, Types.SystemSetupLockMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.SystemSetupLockDocument, defaults)
}

export function waitForSystemSetupLockMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.SystemSetupLockMutation>(Operations.SystemSetupLockDocument)
}

export function mockSystemSetupLockMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.SystemSetupLockDocument, message, extensions);
}
