import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './chatAgentHeartbeat.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockChatAgentHeartbeatMutation(defaults: Mocks.MockDefaultsValue<Types.ChatAgentHeartbeatMutation, Types.ChatAgentHeartbeatMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChatAgentHeartbeatDocument, defaults)
}

export function waitForChatAgentHeartbeatMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChatAgentHeartbeatMutation>(Operations.ChatAgentHeartbeatDocument)
}

export function mockChatAgentHeartbeatMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ChatAgentHeartbeatDocument, message, extensions);
}
