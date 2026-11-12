import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './chatSessionEnd.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockChatSessionEndMutation(defaults: Mocks.MockDefaultsValue<Types.ChatSessionEndMutation, Types.ChatSessionEndMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChatSessionEndDocument, defaults)
}

export function waitForChatSessionEndMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChatSessionEndMutation>(Operations.ChatSessionEndDocument)
}

export function mockChatSessionEndMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ChatSessionEndDocument, message, extensions);
}
