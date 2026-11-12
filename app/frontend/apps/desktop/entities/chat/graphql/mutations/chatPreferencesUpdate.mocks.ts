import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './chatPreferencesUpdate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockChatPreferencesUpdateMutation(defaults: Mocks.MockDefaultsValue<Types.ChatPreferencesUpdateMutation, Types.ChatPreferencesUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChatPreferencesUpdateDocument, defaults)
}

export function waitForChatPreferencesUpdateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChatPreferencesUpdateMutation>(Operations.ChatPreferencesUpdateDocument)
}

export function mockChatPreferencesUpdateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ChatPreferencesUpdateDocument, message, extensions);
}
