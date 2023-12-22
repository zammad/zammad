import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './locale.api.ts'

export function mockAccountLocaleMutation(defaults: Mocks.MockDefaultsValue<Types.AccountLocaleMutation, Types.AccountLocaleMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountLocaleDocument, defaults)
}

export function waitForAccountLocaleMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountLocaleMutation>(Operations.AccountLocaleDocument)
}
