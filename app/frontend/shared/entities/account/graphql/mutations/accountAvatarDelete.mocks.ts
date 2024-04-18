import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountAvatarDelete.api.ts'

export function mockAccountAvatarDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.AccountAvatarDeleteMutation, Types.AccountAvatarDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountAvatarDeleteDocument, defaults)
}

export function waitForAccountAvatarDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountAvatarDeleteMutation>(Operations.AccountAvatarDeleteDocument)
}
