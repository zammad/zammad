import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentLinkedAccount.api.ts'

export function mockUserCurrentRemoveLinkedAccountMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentRemoveLinkedAccountMutation, Types.UserCurrentRemoveLinkedAccountMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentRemoveLinkedAccountDocument, defaults)
}

export function waitForUserCurrentRemoveLinkedAccountMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentRemoveLinkedAccountMutation>(Operations.UserCurrentRemoveLinkedAccountDocument)
}
