import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './chatSessionAccept.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockChatSessionAcceptMutation(defaults: Mocks.MockDefaultsValue<Types.ChatSessionAcceptMutation, Types.ChatSessionAcceptMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChatSessionAcceptDocument, defaults)
}

export function waitForChatSessionAcceptMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChatSessionAcceptMutation>(Operations.ChatSessionAcceptDocument)
}

export function mockChatSessionAcceptMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ChatSessionAcceptDocument, message, extensions);
}
