import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTaskbarItemListPrio.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentTaskbarItemListPrioMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTaskbarItemListPrioMutation, Types.UserCurrentTaskbarItemListPrioMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTaskbarItemListPrioDocument, defaults)
}

export function waitForUserCurrentTaskbarItemListPrioMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTaskbarItemListPrioMutation>(Operations.UserCurrentTaskbarItemListPrioDocument)
}

export function mockUserCurrentTaskbarItemListPrioMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentTaskbarItemListPrioDocument, message, extensions);
}
