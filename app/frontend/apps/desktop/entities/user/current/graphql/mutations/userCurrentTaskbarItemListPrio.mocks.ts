import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTaskbarItemListPrio.api.ts'

export function mockUserCurrentTaskbarItemListPrioMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTaskbarItemListPrioMutation, Types.UserCurrentTaskbarItemListPrioMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTaskbarItemListPrioDocument, defaults)
}

export function waitForUserCurrentTaskbarItemListPrioMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTaskbarItemListPrioMutation>(Operations.UserCurrentTaskbarItemListPrioDocument)
}
