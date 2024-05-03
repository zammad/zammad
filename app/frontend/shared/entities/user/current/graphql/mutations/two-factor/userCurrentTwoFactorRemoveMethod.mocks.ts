import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTwoFactorRemoveMethod.api.ts'

export function mockUserCurrentTwoFactorRemoveMethodMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTwoFactorRemoveMethodMutation, Types.UserCurrentTwoFactorRemoveMethodMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTwoFactorRemoveMethodDocument, defaults)
}

export function waitForUserCurrentTwoFactorRemoveMethodMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTwoFactorRemoveMethodMutation>(Operations.UserCurrentTwoFactorRemoveMethodDocument)
}
