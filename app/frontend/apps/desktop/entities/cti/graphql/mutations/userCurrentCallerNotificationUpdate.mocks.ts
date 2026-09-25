import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentCallerNotificationUpdate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentCallerNotificationUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentCallerNotificationUpdateMutation, Types.UserCurrentCallerNotificationUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentCallerNotificationUpdateDocument, defaults)
}

export function waitForUserCurrentCallerNotificationUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentCallerNotificationUpdateMutation>(Operations.UserCurrentCallerNotificationUpdateDocument)
}

export function mockUserCurrentCallerNotificationUpdateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentCallerNotificationUpdateDocument, message, extensions);
}
