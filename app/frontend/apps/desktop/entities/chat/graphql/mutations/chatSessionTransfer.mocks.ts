import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './chatSessionTransfer.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockChatSessionTransferMutation(defaults: Mocks.MockDefaultsValue<Types.ChatSessionTransferMutation, Types.ChatSessionTransferMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChatSessionTransferDocument, defaults)
}

export function waitForChatSessionTransferMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChatSessionTransferMutation>(Operations.ChatSessionTransferDocument)
}

export function mockChatSessionTransferMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ChatSessionTransferDocument, message, extensions);
}
