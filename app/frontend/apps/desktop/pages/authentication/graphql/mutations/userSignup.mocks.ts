import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userSignup.api.ts'

export function mockUserSignupMutation(defaults: Mocks.MockDefaultsValue<Types.UserSignupMutation, Types.UserSignupMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserSignupDocument, defaults)
}

export function waitForUserSignupMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserSignupMutation>(Operations.UserSignupDocument)
}
