import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './update.api.ts'

export function mockUserUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.UserUpdateMutation, Types.UserUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserUpdateDocument, defaults)
}

export function waitForUserUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserUpdateMutation>(Operations.UserUpdateDocument)
}
