import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './update.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.UserUpdateMutation, Types.UserUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserUpdateDocument, defaults)
}

export function waitForUserUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserUpdateMutation>(Operations.UserUpdateDocument)
}

export function mockUserUpdateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserUpdateDocument, message, extensions);
}
