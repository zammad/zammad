import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userPasswordResetSend.api.ts'

export function mockUserPasswordResetSendMutation(defaults: Mocks.MockDefaultsValue<Types.UserPasswordResetSendMutation, Types.UserPasswordResetSendMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserPasswordResetSendDocument, defaults)
}

export function waitForUserPasswordResetSendMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserPasswordResetSendMutation>(Operations.UserPasswordResetSendDocument)
}
