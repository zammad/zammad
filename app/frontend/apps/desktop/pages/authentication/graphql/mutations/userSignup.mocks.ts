import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userSignup.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserSignupMutation(defaults: Mocks.MockDefaultsValue<Types.UserSignupMutation, Types.UserSignupMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserSignupDocument, defaults)
}

export function waitForUserSignupMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserSignupMutation>(Operations.UserSignupDocument)
}

export function mockUserSignupMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserSignupDocument, message, extensions);
}
