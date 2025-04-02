import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTwoFactorSetDefaultMethod.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentTwoFactorSetDefaultMethodMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTwoFactorSetDefaultMethodMutation, Types.UserCurrentTwoFactorSetDefaultMethodMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTwoFactorSetDefaultMethodDocument, defaults)
}

export function waitForUserCurrentTwoFactorSetDefaultMethodMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTwoFactorSetDefaultMethodMutation>(Operations.UserCurrentTwoFactorSetDefaultMethodDocument)
}

export function mockUserCurrentTwoFactorSetDefaultMethodMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentTwoFactorSetDefaultMethodDocument, message, extensions);
}
