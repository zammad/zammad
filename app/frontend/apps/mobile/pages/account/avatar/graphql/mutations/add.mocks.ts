import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './add.api.ts'

export function mockAccountAvatarAddMutation(defaults: Mocks.MockDefaultsValue<Types.AccountAvatarAddMutation, Types.AccountAvatarAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountAvatarAddDocument, defaults)
}

export function waitForAccountAvatarAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountAvatarAddMutation>(Operations.AccountAvatarAddDocument)
}
