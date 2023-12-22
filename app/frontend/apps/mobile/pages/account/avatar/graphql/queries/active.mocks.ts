import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './active.api.ts'

export function mockAccountAvatarActiveQuery(defaults: Mocks.MockDefaultsValue<Types.AccountAvatarActiveQuery, Types.AccountAvatarActiveQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountAvatarActiveDocument, defaults)
}

export function waitForAccountAvatarActiveQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountAvatarActiveQuery>(Operations.AccountAvatarActiveDocument)
}
