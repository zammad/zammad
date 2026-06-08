import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentRecentCloseReset.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentRecentCloseResetMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentRecentCloseResetMutation, Types.UserCurrentRecentCloseResetMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentRecentCloseResetDocument, defaults)
}

export function waitForUserCurrentRecentCloseResetMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentRecentCloseResetMutation>(Operations.UserCurrentRecentCloseResetDocument)
}

export function mockUserCurrentRecentCloseResetMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentRecentCloseResetDocument, message, extensions);
}
