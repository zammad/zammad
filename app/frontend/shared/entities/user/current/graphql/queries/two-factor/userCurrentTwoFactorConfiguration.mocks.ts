import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTwoFactorConfiguration.api.ts'

export function mockUserCurrentTwoFactorConfigurationQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTwoFactorConfigurationQuery, Types.UserCurrentTwoFactorConfigurationQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTwoFactorConfigurationDocument, defaults)
}

export function waitForUserCurrentTwoFactorConfigurationQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTwoFactorConfigurationQuery>(Operations.UserCurrentTwoFactorConfigurationDocument)
}
