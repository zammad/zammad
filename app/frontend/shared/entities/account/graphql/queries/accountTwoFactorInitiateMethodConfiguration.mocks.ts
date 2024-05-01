import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountTwoFactorInitiateMethodConfiguration.api.ts'

export function mockAccountTwoFactorInitiateMethodConfigurationQuery(defaults: Mocks.MockDefaultsValue<Types.AccountTwoFactorInitiateMethodConfigurationQuery, Types.AccountTwoFactorInitiateMethodConfigurationQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountTwoFactorInitiateMethodConfigurationDocument, defaults)
}

export function waitForAccountTwoFactorInitiateMethodConfigurationQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountTwoFactorInitiateMethodConfigurationQuery>(Operations.AccountTwoFactorInitiateMethodConfigurationDocument)
}
