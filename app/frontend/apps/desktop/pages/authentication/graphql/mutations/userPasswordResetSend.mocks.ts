import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userPasswordResetSend.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserPasswordResetSendMutation(defaults: Mocks.MockDefaultsValue<Types.UserPasswordResetSendMutation, Types.UserPasswordResetSendMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserPasswordResetSendDocument, defaults)
}

export function waitForUserPasswordResetSendMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserPasswordResetSendMutation>(Operations.UserPasswordResetSendDocument)
}

export function mockUserPasswordResetSendMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserPasswordResetSendDocument, message, extensions);
}
