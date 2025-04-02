import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTwoFactorRemoveMethod.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentTwoFactorRemoveMethodMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTwoFactorRemoveMethodMutation, Types.UserCurrentTwoFactorRemoveMethodMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTwoFactorRemoveMethodDocument, defaults)
}

export function waitForUserCurrentTwoFactorRemoveMethodMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTwoFactorRemoveMethodMutation>(Operations.UserCurrentTwoFactorRemoveMethodDocument)
}

export function mockUserCurrentTwoFactorRemoveMethodMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentTwoFactorRemoveMethodDocument, message, extensions);
}
