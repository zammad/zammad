import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountTwoFactorRemoveMethodCredentials.api.ts'

export function mockAccountTwoFactorRemoveMethodCredentialsMutation(defaults: Mocks.MockDefaultsValue<Types.AccountTwoFactorRemoveMethodCredentialsMutation, Types.AccountTwoFactorRemoveMethodCredentialsMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountTwoFactorRemoveMethodCredentialsDocument, defaults)
}

export function waitForAccountTwoFactorRemoveMethodCredentialsMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountTwoFactorRemoveMethodCredentialsMutation>(Operations.AccountTwoFactorRemoveMethodCredentialsDocument)
}
