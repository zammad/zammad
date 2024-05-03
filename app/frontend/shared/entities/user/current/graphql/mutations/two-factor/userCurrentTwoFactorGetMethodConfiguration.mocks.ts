import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTwoFactorGetMethodConfiguration.api.ts'

export function mockUserCurrentTwoFactorGetMethodConfigurationQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTwoFactorGetMethodConfigurationQuery, Types.UserCurrentTwoFactorGetMethodConfigurationQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTwoFactorGetMethodConfigurationDocument, defaults)
}

export function waitForUserCurrentTwoFactorGetMethodConfigurationQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTwoFactorGetMethodConfigurationQuery>(Operations.UserCurrentTwoFactorGetMethodConfigurationDocument)
}
