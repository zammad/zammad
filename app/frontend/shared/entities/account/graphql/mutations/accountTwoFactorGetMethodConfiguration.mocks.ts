import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountTwoFactorGetMethodConfiguration.api.ts'

export function mockAccountTwoFactorGetMethodConfigurationQuery(defaults: Mocks.MockDefaultsValue<Types.AccountTwoFactorGetMethodConfigurationQuery, Types.AccountTwoFactorGetMethodConfigurationQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountTwoFactorGetMethodConfigurationDocument, defaults)
}

export function waitForAccountTwoFactorGetMethodConfigurationQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountTwoFactorGetMethodConfigurationQuery>(Operations.AccountTwoFactorGetMethodConfigurationDocument)
}
