import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTwoFactorInitiateMethodConfiguration.api.ts'

export function mockUserCurrentTwoFactorInitiateMethodConfigurationQuery(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTwoFactorInitiateMethodConfigurationQuery, Types.UserCurrentTwoFactorInitiateMethodConfigurationQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTwoFactorInitiateMethodConfigurationDocument, defaults)
}

export function waitForUserCurrentTwoFactorInitiateMethodConfigurationQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTwoFactorInitiateMethodConfigurationQuery>(Operations.UserCurrentTwoFactorInitiateMethodConfigurationDocument)
}
