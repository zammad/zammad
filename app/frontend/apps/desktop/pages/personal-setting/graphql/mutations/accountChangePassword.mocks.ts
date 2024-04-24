import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './accountChangePassword.api.ts'

export function mockAccountChangePasswordMutation(defaults: Mocks.MockDefaultsValue<Types.AccountChangePasswordMutation, Types.AccountChangePasswordMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AccountChangePasswordDocument, defaults)
}

export function waitForAccountChangePasswordMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AccountChangePasswordMutation>(Operations.AccountChangePasswordDocument)
}
