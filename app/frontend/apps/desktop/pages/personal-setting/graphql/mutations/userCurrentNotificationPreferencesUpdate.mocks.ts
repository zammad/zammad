import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentNotificationPreferencesUpdate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentNotificationPreferencesUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentNotificationPreferencesUpdateMutation, Types.UserCurrentNotificationPreferencesUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentNotificationPreferencesUpdateDocument, defaults)
}

export function waitForUserCurrentNotificationPreferencesUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentNotificationPreferencesUpdateMutation>(Operations.UserCurrentNotificationPreferencesUpdateDocument)
}

export function mockUserCurrentNotificationPreferencesUpdateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentNotificationPreferencesUpdateDocument, message, extensions);
}
