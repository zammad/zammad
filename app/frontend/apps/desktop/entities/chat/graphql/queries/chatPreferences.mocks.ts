import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './chatPreferences.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockChatPreferencesQuery(defaults: Mocks.MockDefaultsValue<Types.ChatPreferencesQuery, Types.ChatPreferencesQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChatPreferencesDocument, defaults)
}

export function waitForChatPreferencesQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChatPreferencesQuery>(Operations.ChatPreferencesDocument)
}

export function mockChatPreferencesQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ChatPreferencesDocument, message, extensions);
}
