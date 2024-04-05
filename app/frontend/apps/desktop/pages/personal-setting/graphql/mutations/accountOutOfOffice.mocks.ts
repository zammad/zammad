import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountOutOfOffice.api.ts'

export function mockAccountOutOfOfficeMutation(defaults: Mocks.MockDefaultsValue<Types.AccountOutOfOfficeMutation, Types.AccountOutOfOfficeMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountOutOfOfficeDocument, defaults)
}

export function waitForAccountOutOfOfficeMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountOutOfOfficeMutation>(Operations.AccountOutOfOfficeDocument)
}
