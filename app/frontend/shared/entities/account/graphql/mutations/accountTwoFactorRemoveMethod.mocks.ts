import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountTwoFactorRemoveMethod.api.ts'

export function mockAccountTwoFactorRemoveMethodMutation(defaults: Mocks.MockDefaultsValue<Types.AccountTwoFactorRemoveMethodMutation, Types.AccountTwoFactorRemoveMethodMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountTwoFactorRemoveMethodDocument, defaults)
}

export function waitForAccountTwoFactorRemoveMethodMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountTwoFactorRemoveMethodMutation>(Operations.AccountTwoFactorRemoveMethodDocument)
}
