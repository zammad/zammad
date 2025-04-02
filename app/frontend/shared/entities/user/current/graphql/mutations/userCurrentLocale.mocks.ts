import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentLocale.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentLocaleMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentLocaleMutation, Types.UserCurrentLocaleMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentLocaleDocument, defaults)
}

export function waitForUserCurrentLocaleMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentLocaleMutation>(Operations.UserCurrentLocaleDocument)
}

export function mockUserCurrentLocaleMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentLocaleDocument, message, extensions);
}
