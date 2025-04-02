import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTaskbarItemAdd.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentTaskbarItemAddMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTaskbarItemAddMutation, Types.UserCurrentTaskbarItemAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTaskbarItemAddDocument, defaults)
}

export function waitForUserCurrentTaskbarItemAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTaskbarItemAddMutation>(Operations.UserCurrentTaskbarItemAddDocument)
}

export function mockUserCurrentTaskbarItemAddMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentTaskbarItemAddDocument, message, extensions);
}
