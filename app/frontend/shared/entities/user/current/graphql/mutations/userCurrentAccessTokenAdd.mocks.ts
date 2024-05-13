import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentAccessTokenAdd.api.ts'

export function mockUserCurrentAccessTokenAddMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentAccessTokenAddMutation, Types.UserCurrentAccessTokenAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentAccessTokenAddDocument, defaults)
}

export function waitForUserCurrentAccessTokenAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentAccessTokenAddMutation>(Operations.UserCurrentAccessTokenAddDocument)
}
