import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userPasswordResetUpdate.api.ts'

export function mockUserPasswordResetUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.UserPasswordResetUpdateMutation, Types.UserPasswordResetUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserPasswordResetUpdateDocument, defaults)
}

export function waitForUserPasswordResetUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserPasswordResetUpdateMutation>(Operations.UserPasswordResetUpdateDocument)
}
