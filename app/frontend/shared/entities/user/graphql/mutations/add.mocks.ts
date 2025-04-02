import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './add.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserAddMutation(defaults: Mocks.MockDefaultsValue<Types.UserAddMutation, Types.UserAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserAddDocument, defaults)
}

export function waitForUserAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserAddMutation>(Operations.UserAddDocument)
}

export function mockUserAddMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserAddDocument, message, extensions);
}
