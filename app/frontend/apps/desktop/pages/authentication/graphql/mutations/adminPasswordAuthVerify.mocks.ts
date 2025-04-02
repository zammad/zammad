import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './adminPasswordAuthVerify.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockAdminPasswordAuthVerifyMutation(defaults: Mocks.MockDefaultsValue<Types.AdminPasswordAuthVerifyMutation, Types.AdminPasswordAuthVerifyMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.AdminPasswordAuthVerifyDocument, defaults)
}

export function waitForAdminPasswordAuthVerifyMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AdminPasswordAuthVerifyMutation>(Operations.AdminPasswordAuthVerifyDocument)
}

export function mockAdminPasswordAuthVerifyMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.AdminPasswordAuthVerifyDocument, message, extensions);
}
