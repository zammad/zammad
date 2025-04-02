import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentOutOfOffice.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentOutOfOfficeMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentOutOfOfficeMutation, Types.UserCurrentOutOfOfficeMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentOutOfOfficeDocument, defaults)
}

export function waitForUserCurrentOutOfOfficeMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentOutOfOfficeMutation>(Operations.UserCurrentOutOfOfficeDocument)
}

export function mockUserCurrentOutOfOfficeMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentOutOfOfficeDocument, message, extensions);
}
