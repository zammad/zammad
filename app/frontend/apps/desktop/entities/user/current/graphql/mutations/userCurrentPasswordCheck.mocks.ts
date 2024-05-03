import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentPasswordCheck.api.ts'

export function mockUserCurrentPasswordCheckMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentPasswordCheckMutation, Types.UserCurrentPasswordCheckMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentPasswordCheckDocument, defaults)
}

export function waitForUserCurrentPasswordCheckMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentPasswordCheckMutation>(Operations.UserCurrentPasswordCheckDocument)
}
