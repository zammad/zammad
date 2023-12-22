import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './adminPasswordAuthSend.api.ts'

export function mockAdminPasswordAuthSendMutation(defaults: Mocks.MockDefaultsValue<Types.AdminPasswordAuthSendMutation, Types.AdminPasswordAuthSendMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AdminPasswordAuthSendDocument, defaults)
}

export function waitForAdminPasswordAuthSendMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AdminPasswordAuthSendMutation>(Operations.AdminPasswordAuthSendDocument)
}
