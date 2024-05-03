import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentLocale.api.ts'

export function mockUserCurrentLocaleMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentLocaleMutation, Types.UserCurrentLocaleMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentLocaleDocument, defaults)
}

export function waitForUserCurrentLocaleMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentLocaleMutation>(Operations.UserCurrentLocaleDocument)
}
