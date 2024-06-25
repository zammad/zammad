import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './user.api.ts'

export function mockUserQuery(defaults: Mocks.MockDefaultsValue<Types.UserQuery, Types.UserQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserDocument, defaults)
}

export function waitForUserQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserQuery>(Operations.UserDocument)
}
