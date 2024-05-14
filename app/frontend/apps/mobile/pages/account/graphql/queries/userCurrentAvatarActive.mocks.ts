import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentAvatarActive.api.ts'

export function mockUserCurrentAvatarActiveQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentAvatarActiveQuery, Types.UserCurrentAvatarActiveQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentAvatarActiveDocument, defaults)
}

export function waitForUserCurrentAvatarActiveQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentAvatarActiveQuery>(Operations.UserCurrentAvatarActiveDocument)
}
