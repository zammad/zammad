import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountTwoFactorRecoveryCodesGenerate.api.ts'

export function mockAccountTwoFactorRecoveryCodesGenerateMutation(defaults: Mocks.MockDefaultsValue<Types.AccountTwoFactorRecoveryCodesGenerateMutation, Types.AccountTwoFactorRecoveryCodesGenerateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountTwoFactorRecoveryCodesGenerateDocument, defaults)
}

export function waitForAccountTwoFactorRecoveryCodesGenerateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountTwoFactorRecoveryCodesGenerateMutation>(Operations.AccountTwoFactorRecoveryCodesGenerateDocument)
}
