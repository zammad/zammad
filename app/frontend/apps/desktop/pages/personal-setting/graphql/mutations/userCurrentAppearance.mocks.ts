import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentAppearance.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentAppearanceMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentAppearanceMutation, Types.UserCurrentAppearanceMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentAppearanceDocument, defaults)
}

export function waitForUserCurrentAppearanceMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentAppearanceMutation>(Operations.UserCurrentAppearanceDocument)
}

export function mockUserCurrentAppearanceMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentAppearanceDocument, message, extensions);
}
