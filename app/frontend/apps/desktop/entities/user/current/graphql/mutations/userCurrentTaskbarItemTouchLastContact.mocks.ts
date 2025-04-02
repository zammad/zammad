import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTaskbarItemTouchLastContact.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentTaskbarItemTouchLastContactMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTaskbarItemTouchLastContactMutation, Types.UserCurrentTaskbarItemTouchLastContactMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTaskbarItemTouchLastContactDocument, defaults)
}

export function waitForUserCurrentTaskbarItemTouchLastContactMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTaskbarItemTouchLastContactMutation>(Operations.UserCurrentTaskbarItemTouchLastContactDocument)
}

export function mockUserCurrentTaskbarItemTouchLastContactMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentTaskbarItemTouchLastContactDocument, message, extensions);
}
