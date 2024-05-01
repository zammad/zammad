import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountTwoFactorVerifyMethodConfiguration.api.ts'

export function mockAccountTwoFactorVerifyMethodConfigurationMutation(defaults: Mocks.MockDefaultsValue<Types.AccountTwoFactorVerifyMethodConfigurationMutation, Types.AccountTwoFactorVerifyMethodConfigurationMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountTwoFactorVerifyMethodConfigurationDocument, defaults)
}

export function waitForAccountTwoFactorVerifyMethodConfigurationMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountTwoFactorVerifyMethodConfigurationMutation>(Operations.AccountTwoFactorVerifyMethodConfigurationDocument)
}
