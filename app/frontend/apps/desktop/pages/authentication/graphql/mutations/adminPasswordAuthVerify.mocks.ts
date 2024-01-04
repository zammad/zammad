import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './adminPasswordAuthVerify.api.ts'

export function mockAdminPasswordAuthVerifyMutation(defaults: Mocks.MockDefaultsValue<Types.AdminPasswordAuthVerifyMutation, Types.AdminPasswordAuthVerifyMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AdminPasswordAuthVerifyDocument, defaults)
}

export function waitForAdminPasswordAuthVerifyMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AdminPasswordAuthVerifyMutation>(Operations.AdminPasswordAuthVerifyDocument)
}
