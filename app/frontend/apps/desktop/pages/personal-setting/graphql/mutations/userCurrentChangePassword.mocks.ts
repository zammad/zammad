import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentChangePassword.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentChangePasswordMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentChangePasswordMutation, Types.UserCurrentChangePasswordMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentChangePasswordDocument, defaults)
}

export function waitForUserCurrentChangePasswordMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentChangePasswordMutation>(Operations.UserCurrentChangePasswordDocument)
}

export function mockUserCurrentChangePasswordMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentChangePasswordDocument, message, extensions);
}
