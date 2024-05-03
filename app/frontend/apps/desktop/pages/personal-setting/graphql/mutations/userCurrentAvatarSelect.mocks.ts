import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentAvatarSelect.api.ts'

export function mockUserCurrentAvatarSelectMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentAvatarSelectMutation, Types.UserCurrentAvatarSelectMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentAvatarSelectDocument, defaults)
}

export function waitForUserCurrentAvatarSelectMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentAvatarSelectMutation>(Operations.UserCurrentAvatarSelectDocument)
}
