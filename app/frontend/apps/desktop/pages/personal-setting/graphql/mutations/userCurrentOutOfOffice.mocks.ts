import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentOutOfOffice.api.ts'

export function mockUserCurrentOutOfOfficeMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentOutOfOfficeMutation, Types.UserCurrentOutOfOfficeMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentOutOfOfficeDocument, defaults)
}

export function waitForUserCurrentOutOfOfficeMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentOutOfOfficeMutation>(Operations.UserCurrentOutOfOfficeDocument)
}
