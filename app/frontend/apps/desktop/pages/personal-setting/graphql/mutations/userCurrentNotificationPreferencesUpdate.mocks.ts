import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentNotificationPreferencesUpdate.api.ts'

export function mockUserCurrentNotificationPreferencesUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.UserCurrentNotificationPreferencesUpdateMutation, Types.UserCurrentNotificationPreferencesUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentNotificationPreferencesUpdateDocument, defaults)
}

export function waitForUserCurrentNotificationPreferencesUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentNotificationPreferencesUpdateMutation>(Operations.UserCurrentNotificationPreferencesUpdateDocument)
}
