import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './chatSessionRename.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockChatSessionRenameMutation(defaults: Mocks.MockDefaultsValue<Types.ChatSessionRenameMutation, Types.ChatSessionRenameMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChatSessionRenameDocument, defaults)
}

export function waitForChatSessionRenameMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChatSessionRenameMutation>(Operations.ChatSessionRenameDocument)
}

export function mockChatSessionRenameMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ChatSessionRenameDocument, message, extensions);
}
