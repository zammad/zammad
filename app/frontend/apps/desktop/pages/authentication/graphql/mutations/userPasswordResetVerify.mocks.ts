import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userPasswordResetVerify.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserPasswordResetVerifyMutation(defaults: Mocks.MockDefaultsValue<Types.UserPasswordResetVerifyMutation, Types.UserPasswordResetVerifyMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserPasswordResetVerifyDocument, defaults)
}

export function waitForUserPasswordResetVerifyMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserPasswordResetVerifyMutation>(Operations.UserPasswordResetVerifyDocument)
}

export function mockUserPasswordResetVerifyMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserPasswordResetVerifyDocument, message, extensions);
}
