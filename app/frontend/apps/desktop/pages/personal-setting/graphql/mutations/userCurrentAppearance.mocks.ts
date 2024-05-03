import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentAppearance.api.ts'

export function mockUserCurrentAppearanceMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentAppearanceMutation, Types.UserCurrentAppearanceMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentAppearanceDocument, defaults)
}

export function waitForUserCurrentAppearanceMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentAppearanceMutation>(Operations.UserCurrentAppearanceDocument)
}
