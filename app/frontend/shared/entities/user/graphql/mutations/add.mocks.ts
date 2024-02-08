import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './add.api.ts'

export function mockUserAddMutation(defaults: Mocks.MockDefaultsValue<Types.UserAddMutation, Types.UserAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserAddDocument, defaults)
}

export function waitForUserAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserAddMutation>(Operations.UserAddDocument)
}
