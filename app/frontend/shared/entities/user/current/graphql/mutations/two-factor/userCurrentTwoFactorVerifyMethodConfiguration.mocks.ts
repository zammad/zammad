import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTwoFactorVerifyMethodConfiguration.api.ts'

export function mockUserCurrentTwoFactorVerifyMethodConfigurationMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTwoFactorVerifyMethodConfigurationMutation, Types.UserCurrentTwoFactorVerifyMethodConfigurationMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTwoFactorVerifyMethodConfigurationDocument, defaults)
}

export function waitForUserCurrentTwoFactorVerifyMethodConfigurationMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTwoFactorVerifyMethodConfigurationMutation>(Operations.UserCurrentTwoFactorVerifyMethodConfigurationDocument)
}
