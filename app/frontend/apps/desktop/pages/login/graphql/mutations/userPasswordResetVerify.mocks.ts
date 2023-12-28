import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userPasswordResetVerify.api.ts'

export function mockUserPasswordResetVerifyMutation(defaults: Mocks.MockDefaultsValue<Types.UserPasswordResetVerifyMutation, Types.UserPasswordResetVerifyMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserPasswordResetVerifyDocument, defaults)
}

export function waitForUserPasswordResetVerifyMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserPasswordResetVerifyMutation>(Operations.UserPasswordResetVerifyDocument)
}
