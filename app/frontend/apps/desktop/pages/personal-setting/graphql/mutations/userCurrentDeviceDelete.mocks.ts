import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentDeviceDelete.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentDeviceDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentDeviceDeleteMutation, Types.UserCurrentDeviceDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentDeviceDeleteDocument, defaults)
}

export function waitForUserCurrentDeviceDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentDeviceDeleteMutation>(Operations.UserCurrentDeviceDeleteDocument)
}

export function mockUserCurrentDeviceDeleteMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentDeviceDeleteDocument, message, extensions);
}
