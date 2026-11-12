import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './chatSessionMessageAdd.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockChatSessionMessageAddMutation(defaults: Mocks.MockDefaultsValue<Types.ChatSessionMessageAddMutation, Types.ChatSessionMessageAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChatSessionMessageAddDocument, defaults)
}

export function waitForChatSessionMessageAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChatSessionMessageAddMutation>(Operations.ChatSessionMessageAddDocument)
}

export function mockChatSessionMessageAddMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ChatSessionMessageAddDocument, message, extensions);
}
