import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentPasswordCheck.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentPasswordCheckMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentPasswordCheckMutation, Types.UserCurrentPasswordCheckMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentPasswordCheckDocument, defaults)
}

export function waitForUserCurrentPasswordCheckMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentPasswordCheckMutation>(Operations.UserCurrentPasswordCheckDocument)
}

export function mockUserCurrentPasswordCheckMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentPasswordCheckDocument, message, extensions);
}
