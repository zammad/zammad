import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountAppearance.api.ts'

export function mockAccountAppearanceMutation(defaults: Mocks.MockDefaultsValue<Types.AccountAppearanceMutation, Types.AccountAppearanceMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountAppearanceDocument, defaults)
}

export function waitForAccountAppearanceMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountAppearanceMutation>(Operations.AccountAppearanceDocument)
}
