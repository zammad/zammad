import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTaskbarItemAdd.api.ts'

export function mockUserCurrentTaskbarItemAddMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTaskbarItemAddMutation, Types.UserCurrentTaskbarItemAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTaskbarItemAddDocument, defaults)
}

export function waitForUserCurrentTaskbarItemAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTaskbarItemAddMutation>(Operations.UserCurrentTaskbarItemAddDocument)
}
