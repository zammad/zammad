import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userSignupResend.api.ts'

export function mockUserSignupResendMutation(defaults: Mocks.MockDefaultsValue<Types.UserSignupResendMutation, Types.UserSignupResendMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserSignupResendDocument, defaults)
}

export function waitForUserSignupResendMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserSignupResendMutation>(Operations.UserSignupResendDocument)
}
