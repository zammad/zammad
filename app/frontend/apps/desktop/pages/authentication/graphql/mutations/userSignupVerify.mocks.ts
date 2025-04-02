import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userSignupVerify.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserSignupVerifyMutation(defaults: Mocks.MockDefaultsValue<Types.UserSignupVerifyMutation, Types.UserSignupVerifyMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserSignupVerifyDocument, defaults)
}

export function waitForUserSignupVerifyMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserSignupVerifyMutation>(Operations.UserSignupVerifyDocument)
}

export function mockUserSignupVerifyMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserSignupVerifyDocument, message, extensions);
}
