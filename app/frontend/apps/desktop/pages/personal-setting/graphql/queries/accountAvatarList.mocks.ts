import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountAvatarList.api.ts'

export function mockAccountAvatarListQuery(defaults: Mocks.MockDefaultsValue<Types.AccountAvatarListQuery, Types.AccountAvatarListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountAvatarListDocument, defaults)
}

export function waitForAccountAvatarListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountAvatarListQuery>(Operations.AccountAvatarListDocument)
}
