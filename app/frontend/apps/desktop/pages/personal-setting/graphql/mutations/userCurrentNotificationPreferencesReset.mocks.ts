import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentNotificationPreferencesReset.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentNotificationPreferencesResetMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentNotificationPreferencesResetMutation, Types.UserCurrentNotificationPreferencesResetMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentNotificationPreferencesResetDocument, defaults)
}

export function waitForUserCurrentNotificationPreferencesResetMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentNotificationPreferencesResetMutation>(Operations.UserCurrentNotificationPreferencesResetDocument)
}

export function mockUserCurrentNotificationPreferencesResetMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentNotificationPreferencesResetDocument, message, extensions);
}
