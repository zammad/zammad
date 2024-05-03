import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentAvatarDelete.api.ts'

export function mockUserCurrentAvatarDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentAvatarDeleteMutation, Types.UserCurrentAvatarDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentAvatarDeleteDocument, defaults)
}

export function waitForUserCurrentAvatarDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentAvatarDeleteMutation>(Operations.UserCurrentAvatarDeleteDocument)
}
