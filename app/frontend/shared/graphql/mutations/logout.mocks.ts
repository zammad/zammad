import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './logout.api.ts'

export function mockLogoutMutation(defaults: Mocks.MockDefaultsValue<Types.LogoutMutation, Types.LogoutMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.LogoutDocument, defaults)
}

export function waitForLogoutMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.LogoutMutation>(Operations.LogoutDocument)
}
