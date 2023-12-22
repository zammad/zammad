import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './currentUser.api.ts'

export function mockCurrentUserQuery(defaults: Mocks.MockDefaultsValue<Types.CurrentUserQuery, Types.CurrentUserQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.CurrentUserDocument, defaults)
}

export function waitForCurrentUserQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.CurrentUserQuery>(Operations.CurrentUserDocument)
}
