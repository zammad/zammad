import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountAvatarSelect.api.ts'

export function mockAccountAvatarSelectMutation(defaults: Mocks.MockDefaultsValue<Types.AccountAvatarSelectMutation, Types.AccountAvatarSelectMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountAvatarSelectDocument, defaults)
}

export function waitForAccountAvatarSelectMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountAvatarSelectMutation>(Operations.AccountAvatarSelectDocument)
}
