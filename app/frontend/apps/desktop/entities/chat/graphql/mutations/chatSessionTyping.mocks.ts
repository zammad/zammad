import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './chatSessionTyping.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockChatSessionTypingMutation(defaults: Mocks.MockDefaultsValue<Types.ChatSessionTypingMutation, Types.ChatSessionTypingMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChatSessionTypingDocument, defaults)
}

export function waitForChatSessionTypingMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChatSessionTypingMutation>(Operations.ChatSessionTypingDocument)
}

export function mockChatSessionTypingMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ChatSessionTypingDocument, message, extensions);
}
