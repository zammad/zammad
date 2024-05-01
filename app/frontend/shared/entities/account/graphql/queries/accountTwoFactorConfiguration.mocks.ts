import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountTwoFactorConfiguration.api.ts'

export function mockAccountTwoFactorConfigurationQuery(defaults: Mocks.MockDefaultsValue<Types.AccountTwoFactorConfigurationQuery, Types.AccountTwoFactorConfigurationQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountTwoFactorConfigurationDocument, defaults)
}

export function waitForAccountTwoFactorConfigurationQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountTwoFactorConfigurationQuery>(Operations.AccountTwoFactorConfigurationDocument)
}
