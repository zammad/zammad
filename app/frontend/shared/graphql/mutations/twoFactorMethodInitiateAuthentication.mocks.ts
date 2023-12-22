import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './twoFactorMethodInitiateAuthentication.api.ts'

export function mockTwoFactorMethodInitiateAuthenticationMutation(defaults: Mocks.MockDefaultsValue<Types.TwoFactorMethodInitiateAuthenticationMutation, Types.TwoFactorMethodInitiateAuthenticationMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TwoFactorMethodInitiateAuthenticationDocument, defaults)
}

export function waitForTwoFactorMethodInitiateAuthenticationMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TwoFactorMethodInitiateAuthenticationMutation>(Operations.TwoFactorMethodInitiateAuthenticationDocument)
}
