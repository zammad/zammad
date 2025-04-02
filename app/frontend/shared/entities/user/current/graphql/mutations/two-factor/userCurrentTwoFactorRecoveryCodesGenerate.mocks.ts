import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTwoFactorRecoveryCodesGenerate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentTwoFactorRecoveryCodesGenerateMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTwoFactorRecoveryCodesGenerateMutation, Types.UserCurrentTwoFactorRecoveryCodesGenerateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTwoFactorRecoveryCodesGenerateDocument, defaults)
}

export function waitForUserCurrentTwoFactorRecoveryCodesGenerateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTwoFactorRecoveryCodesGenerateMutation>(Operations.UserCurrentTwoFactorRecoveryCodesGenerateDocument)
}

export function mockUserCurrentTwoFactorRecoveryCodesGenerateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentTwoFactorRecoveryCodesGenerateDocument, message, extensions);
}
