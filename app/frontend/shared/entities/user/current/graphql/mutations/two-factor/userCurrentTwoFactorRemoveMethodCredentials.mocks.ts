import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTwoFactorRemoveMethodCredentials.api.ts'

export function mockUserCurrentTwoFactorRemoveMethodCredentialsMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTwoFactorRemoveMethodCredentialsMutation, Types.UserCurrentTwoFactorRemoveMethodCredentialsMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTwoFactorRemoveMethodCredentialsDocument, defaults)
}

export function waitForUserCurrentTwoFactorRemoveMethodCredentialsMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTwoFactorRemoveMethodCredentialsMutation>(Operations.UserCurrentTwoFactorRemoveMethodCredentialsDocument)
}
