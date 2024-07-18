import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentTaskbarItemDelete.api.ts'

export function mockUserCurrentTaskbarItemDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentTaskbarItemDeleteMutation, Types.UserCurrentTaskbarItemDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentTaskbarItemDeleteDocument, defaults)
}

export function waitForUserCurrentTaskbarItemDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentTaskbarItemDeleteMutation>(Operations.UserCurrentTaskbarItemDeleteDocument)
}
