import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userSignupResend.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserSignupResendMutation(defaults: Mocks.MockDefaultsValue<Types.UserSignupResendMutation, Types.UserSignupResendMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserSignupResendDocument, defaults)
}

export function waitForUserSignupResendMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserSignupResendMutation>(Operations.UserSignupResendDocument)
}

export function mockUserSignupResendMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserSignupResendDocument, message, extensions);
}
